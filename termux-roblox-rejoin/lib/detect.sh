#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  DETECT.SH - System to detect "no longer in server"
#  Combines multiple methods to minimize false positives
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh"

# Consecutive CPU idle counter (persists between calls)
CPU_LOW_COUNTER=0

# ============================================================
#  METHOD 1: TOP ACTIVITY CHECK
#  Check if Roblox app is in foreground
# ============================================================
check_activity() {
    local pkg=$1

    # Get top activity from dumpsys - very accurate
    local top=$(su -c "dumpsys activity activities 2>/dev/null" | \
        grep -E "mCurrentFocus|mFocusedActivity|topActivity" | head -3)

    if echo "$top" | grep -q "$pkg"; then
        echo "foreground"
    else
        # Double-check: check recent tasks
        local recent=$(su -c "dumpsys activity recents 2>/dev/null" | \
            grep -E "topActivity.*$pkg" | head -1)
        [ -n "$recent" ] && echo "recent" || echo "background"
    fi
}

# ============================================================
#  METHOD 2: PROCESS CHECK
#  Check if package PID is still alive
# ============================================================
check_process() {
    local pkg=$1

    # Try pidof first (fastest)
    local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')

    # Fallback: use ps if pidof not available
    if [ -z "$pid" ]; then
        pid=$(su -c "ps -A 2>/dev/null | grep '[[:space:]]$pkg$' | awk '{print \$1}' | head -1")
    fi

    # Another fallback: use am dump
    if [ -z "$pid" ]; then
        local running=$(su -c "am dump-heap $pkg /dev/null 2>&1" | grep -c "pid")
        [ "$running" -gt 0 ] && pid="found"
    fi

    if [ -n "$pid" ] && [ "$pid" != "0" ]; then
        echo "running:$pid"
    else
        echo "dead"
    fi
}

# ============================================================
#  METHOD 3: LOGCAT MONITORING
#  Search for disconnect/error keywords in Android log
# ============================================================
check_logcat() {
    local pkg=$1

    # Typical keywords when kicked/disconnected from server
    local DISCONNECT_KEYWORDS="Disconnected|LostConnection|ErrorPrompt|Kicked|Connection failed|Teleport failed|Game closed|PlaceId mismatch|NetworkError|TimeoutError|ServerShutdown|Rejoining"
    # Keywords when in-game (to avoid false positive)
    local INGAME_KEYWORDS="Heartbeat|Workspace|RunService|Player.*Character|RenderStep"

    # Get last 5 seconds of log
    local recent_log=$(su -c "timeout 2 logcat -d -t 100 2>/dev/null" 2>/dev/null)

    # Check for disconnect keyword
    local disconnect_hit=$(echo "$recent_log" | grep -cE "$DISCONNECT_KEYWORDS")
    # Check for in-game keyword (to avoid false positive)
    local ingame_hit=$(echo "$recent_log" | grep -cE "$INGAME_KEYWORDS")

    if [ "$disconnect_hit" -gt 0 ] && [ "$ingame_hit" -eq 0 ]; then
        local matched=$(echo "$recent_log" | grep -oE "$DISCONNECT_KEYWORDS" | head -3 | tr '\n' '|')
        log_warn "Logcat hit: $matched"
        echo "disconnected"
    elif [ "$disconnect_hit" -gt 0 ] && [ "$ingame_hit" -gt 0 ]; then
        # Has both -> uncertain, skip
        echo "uncertain"
    else
        echo "connected"
    fi
}

# ============================================================
#  METHOD 4: CPU MONITORING
#  If process CPU stays low -> app is idle (at home/lobby)
# ============================================================
check_cpu_for_pkg() {
    local pkg=$1
    local threshold=$(get_config ".detection.cpu_threshold // 5")
    local max_low=$(get_config ".detection.cpu_low_duration // 20")

    # Get PID
    local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')
    if [ -z "$pid" ]; then
        echo "no_process"; return
    fi

    # Read CPU time from /proc/PID/stat
    local stat1=$(cat "/proc/$pid/stat" 2>/dev/null)
    if [ -z "$stat1" ]; then echo "no_stat"; return; fi

    local utime1=$(echo "$stat1" | awk '{print $14}')
    local stime1=$(echo "$stat1" | awk '{print $15}')
    sleep 1
    local stat2=$(cat "/proc/$pid/stat" 2>/dev/null)
    if [ -z "$stat2" ]; then echo "no_stat"; return; fi

    local utime2=$(echo "$stat2" | awk '{print $14}')
    local stime2=$(echo "$stat2" | awk '{print $15}')

    # CPU ticks in 1 second
    local delta=$(( (utime2 + stime2) - (utime1 + stime1) ))

    if [ "$delta" -lt "$threshold" ] 2>/dev/null; then
        CPU_LOW_COUNTER=$((CPU_LOW_COUNTER + 1))
        log_info "Low CPU (delta=$delta) | Counter: $CPU_LOW_COUNTER/$max_low"
    else
        # Reset counter when CPU active
        if [ "$CPU_LOW_COUNTER" -gt 0 ]; then
            log_info "CPU active again (delta=$delta) -> reset counter"
        fi
        CPU_LOW_COUNTER=0
    fi

    if [ "$CPU_LOW_COUNTER" -ge "$max_low" ]; then
        CPU_LOW_COUNTER=0  # Reset after trigger
        echo "idle_too_long"
    else
        echo "active"
    fi
}

# ============================================================
#  METHOD 5: NETWORK ACTIVITY CHECK
#  Roblox in-game will have continuous network traffic
# ============================================================
check_network_activity() {
    local pkg=$1
    local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')
    [ -z "$pid" ] && echo "no_process" && return

    # Read process network bytes
    local net1=$(cat "/proc/$pid/net/dev" 2>/dev/null | awk 'NR>2{rx+=$2; tx+=$10} END{print rx+tx}')
    sleep 2
    local net2=$(cat "/proc/$pid/net/dev" 2>/dev/null | awk 'NR>2{rx+=$2; tx+=$10} END{print rx+tx}')

    local delta=$((net2 - net1))
    if [ "$delta" -lt 1000 ]; then
        # Less than 1KB in 2 seconds -> no network activity
        echo "no_traffic"
    else
        echo "has_traffic"
    fi
}

# ============================================================
#  MASTER DETECTOR - Combine all methods
#  Use scoring system to avoid false positives
# ============================================================
detect_need_rejoin() {
    local pkg=$1
    local use_logcat=$(get_config ".detection.use_logcat // true")
    local use_activity=$(get_config ".detection.use_activity // true")
    local use_cpu=$(get_config ".detection.use_cpu // true")

    local score=0
    local reasons=()

    # -- STEP 0: Check process (most important) ----------
    local proc_status=$(check_process "$pkg")
    if [ "$proc_status" = "dead" ]; then
        log_warn "Process $pkg is dead -> need to rejoin immediately!"
        echo "rejoin:process_dead"
        return
    fi

    # -- STEP 1: Activity check (fast, accurate) -----------
    if [ "$use_activity" = "true" ]; then
        local act=$(check_activity "$pkg")
        case "$act" in
            background)
                score=$((score + 3))
                reasons+=("app_in_background")
                ;;
            recent)
                # App still in recents but not foreground
                score=$((score + 1))
                reasons+=("app_in_recent")
                ;;
            foreground)
                # In foreground -> lower risk
                score=$((score - 1))
                ;;
        esac
    fi

    # -- STEP 2: Logcat check ---------------------------------
    if [ "$use_logcat" = "true" ]; then
        local lcat=$(check_logcat "$pkg")
        case "$lcat" in
            disconnected)
                score=$((score + 5))
                reasons+=("logcat_disconnect_detected")
                ;;
            uncertain)
                score=$((score + 1))
                reasons+=("logcat_uncertain")
                ;;
        esac
    fi

    # -- STEP 3: CPU check ------------------------------------
    if [ "$use_cpu" = "true" ]; then
        local cpu_stat=$(check_cpu_for_pkg "$pkg")
        case "$cpu_stat" in
            idle_too_long)
                score=$((score + 2))
                reasons+=("cpu_idle_too_long")
                ;;
            no_process)
                score=$((score + 5))
                reasons+=("cpu_no_process")
                ;;
        esac
    fi

    # -- DECISION -------------------------------------------
    # Rejoin threshold: score >= 3
    if [ "$score" -ge 3 ]; then
        local reason_str
        reason_str=$(IFS='+'; echo "${reasons[*]}")
        log_warn "Score: $score | Reason: $reason_str -> REJOIN"
        echo "rejoin:$reason_str"
    else
        echo "ok"
    fi
}

# ============================================================
#  HELPER: Show detailed detect status (for debug)
# ============================================================
debug_detect() {
    local pkg=${1:-$(get_config ".active_package")}
    echo -e "${CYAN}=== DEBUG DETECT: $pkg ===${RESET}"

    echo -ne "  Process:  "
    check_process "$pkg"

    echo -ne "  Activity: "
    check_activity "$pkg"

    echo -ne "  Logcat:   "
    check_logcat "$pkg"

    echo -ne "  CPU:      "
    check_cpu_for_pkg "$pkg"

    echo ""
    echo "Master decision:"
    detect_need_rejoin "$pkg"
}
