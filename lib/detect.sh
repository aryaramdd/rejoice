#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  DETECT.SH - Hệ thống phát hiện "không còn trong server"
#  Kết hợp đa phương pháp để giảm false positive tối đa
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh"

# Bộ đếm CPU idle liên tiếp (persist giữa các lần gọi)
CPU_LOW_COUNTER=0

# ============================================================
#  PHƯƠNG PHÁP 1: TOP ACTIVITY CHECK
#  Kiểm tra app Roblox có đang ở foreground không
# ============================================================
check_activity() {
    local pkg=$1

    # Lấy top activity từ dumpsys - cực kỳ chính xác
    local top=$(su -c "dumpsys activity activities 2>/dev/null" | \
        grep -E "mCurrentFocus|mFocusedActivity|topActivity" | head -3)

    if echo "$top" | grep -q "$pkg"; then
        echo "foreground"
    else
        # Double-check: kiểm tra recent tasks
        local recent=$(su -c "dumpsys activity recents 2>/dev/null" | \
            grep -E "topActivity.*$pkg" | head -1)
        [ -n "$recent" ] && echo "recent" || echo "background"
    fi
}

# ============================================================
#  PHƯƠNG PHÁP 2: PROCESS CHECK
#  Kiểm tra PID của package còn sống không
# ============================================================
check_process() {
    local pkg=$1

    # Thử pidof trước (nhanh nhất)
    local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')

    # Fallback: dùng ps nếu pidof không có
    if [ -z "$pid" ]; then
        pid=$(su -c "ps -A 2>/dev/null | grep '[[:space:]]$pkg$' | awk '{print \$1}' | head -1")
    fi

    # Fallback nữa: dùng am dump
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
#  PHƯƠNG PHÁP 3: LOGCAT MONITORING
#  Tìm keywords báo hiệu disconnect/lỗi trong log Android
# ============================================================
check_logcat() {
    local pkg=$1

    # Keywords tiêu biểu khi bị kick/disconnect khỏi server
    local DISCONNECT_KEYWORDS="Disconnected|LostConnection|ErrorPrompt|Kicked|Connection failed|Teleport failed|Game closed|PlaceId mismatch|NetworkError|TimeoutError|ServerShutdown|Rejoining"
    # Keywords khi đang trong game (tránh false positive)
    local INGAME_KEYWORDS="Heartbeat|Workspace|RunService|Player.*Character|RenderStep"

    # Lấy log 5 giây gần nhất
    local recent_log=$(su -c "timeout 2 logcat -d -t 100 2>/dev/null" 2>/dev/null)

    # Kiểm tra có keyword disconnect không
    local disconnect_hit=$(echo "$recent_log" | grep -cE "$DISCONNECT_KEYWORDS")
    # Kiểm tra có keyword ingame không (để tránh false positive)
    local ingame_hit=$(echo "$recent_log" | grep -cE "$INGAME_KEYWORDS")

    if [ "$disconnect_hit" -gt 0 ] && [ "$ingame_hit" -eq 0 ]; then
        local matched=$(echo "$recent_log" | grep -oE "$DISCONNECT_KEYWORDS" | head -3 | tr '\n' '|')
        log_warn "Logcat hit: $matched"
        echo "disconnected"
    elif [ "$disconnect_hit" -gt 0 ] && [ "$ingame_hit" -gt 0 ]; then
        # Có cả hai → không chắc, bỏ qua
        echo "uncertain"
    else
        echo "connected"
    fi
}

# ============================================================
#  PHƯƠNG PHÁP 4: CPU MONITORING
#  Nếu process CPU thấp liên tục → app đang idle (ở home/lobby)
# ============================================================
check_cpu_for_pkg() {
    local pkg=$1
    local threshold=$(get_config ".detection.cpu_threshold // 5")
    local max_low=$(get_config ".detection.cpu_low_duration // 20")

    # Lấy PID
    local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')
    if [ -z "$pid" ]; then
        echo "no_process"; return
    fi

    # Đọc CPU time từ /proc/PID/stat
    local stat1=$(cat "/proc/$pid/stat" 2>/dev/null)
    if [ -z "$stat1" ]; then echo "no_stat"; return; fi

    local utime1=$(echo "$stat1" | awk '{print $14}')
    local stime1=$(echo "$stat1" | awk '{print $15}')
    sleep 1
    local stat2=$(cat "/proc/$pid/stat" 2>/dev/null)
    if [ -z "$stat2" ]; then echo "no_stat"; return; fi

    local utime2=$(echo "$stat2" | awk '{print $14}')
    local stime2=$(echo "$stat2" | awk '{print $15}')

    # CPU ticks trong 1 giây
    local delta=$(( (utime2 + stime2) - (utime1 + stime1) ))

    if [ "$delta" -lt "$threshold" ] 2>/dev/null; then
        CPU_LOW_COUNTER=$((CPU_LOW_COUNTER + 1))
        log_info "CPU thấp (delta=$delta) | Counter: $CPU_LOW_COUNTER/$max_low"
    else
        # Reset counter khi CPU active
        if [ "$CPU_LOW_COUNTER" -gt 0 ]; then
            log_info "CPU active trở lại (delta=$delta) → reset counter"
        fi
        CPU_LOW_COUNTER=0
    fi

    if [ "$CPU_LOW_COUNTER" -ge "$max_low" ]; then
        CPU_LOW_COUNTER=0  # Reset sau khi trigger
        echo "idle_too_long"
    else
        echo "active"
    fi
}

# ============================================================
#  PHƯƠNG PHÁP 5: NETWORK ACTIVITY CHECK
#  Roblox trong game sẽ có network traffic liên tục
# ============================================================
check_network_activity() {
    local pkg=$1
    local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')
    [ -z "$pid" ] && echo "no_process" && return

    # Đọc network bytes của process
    local net1=$(cat "/proc/$pid/net/dev" 2>/dev/null | awk 'NR>2{rx+=$2; tx+=$10} END{print rx+tx}')
    sleep 2
    local net2=$(cat "/proc/$pid/net/dev" 2>/dev/null | awk 'NR>2{rx+=$2; tx+=$10} END{print rx+tx}')

    local delta=$((net2 - net1))
    if [ "$delta" -lt 1000 ]; then
        # Ít hơn 1KB trong 2 giây → không có network activity
        echo "no_traffic"
    else
        echo "has_traffic"
    fi
}

# ============================================================
#  MASTER DETECTOR - Tổng hợp tất cả phương pháp
#  Dùng hệ thống tính điểm để tránh false positive
# ============================================================
detect_need_rejoin() {
    local pkg=$1
    local use_logcat=$(get_config ".detection.use_logcat // true")
    local use_activity=$(get_config ".detection.use_activity // true")
    local use_cpu=$(get_config ".detection.use_cpu // true")

    local score=0
    local reasons=()

    # ── BƯỚC 0: Kiểm tra process (quan trọng nhất) ──────────
    local proc_status=$(check_process "$pkg")
    if [ "$proc_status" = "dead" ]; then
        log_warn "Process $pkg đã chết → cần rejoin ngay!"
        echo "rejoin:process_dead"
        return
    fi

    # ── BƯỚC 1: Activity check (nhanh, chính xác) ────────────
    if [ "$use_activity" = "true" ]; then
        local act=$(check_activity "$pkg")
        case "$act" in
            background)
                score=$((score + 3))
                reasons+=("app_in_background")
                ;;
            recent)
                # App còn trong recent nhưng không phải foreground
                score=$((score + 1))
                reasons+=("app_in_recent")
                ;;
            foreground)
                # Đang ở foreground → giảm nguy cơ
                score=$((score - 1))
                ;;
        esac
    fi

    # ── BƯỚC 2: Logcat check ─────────────────────────────────
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

    # ── BƯỚC 3: CPU check ────────────────────────────────────
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

    # ── QUYẾT ĐỊNH ────────────────────────────────────────────
    # Ngưỡng rejoin: score >= 3
    if [ "$score" -ge 3 ]; then
        local reason_str
        reason_str=$(IFS='+'; echo "${reasons[*]}")
        log_warn "Score: $score | Lý do: $reason_str → REJOIN"
        echo "rejoin:$reason_str"
    else
        echo "ok"
    fi
}

# ============================================================
#  HELPER: Hiển thị trạng thái detect chi tiết (cho debug)
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
