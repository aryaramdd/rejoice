#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  TERMUX ROBLOX AUTO REJOIN - ONE-COMMAND INSTALLER
#  Just paste 1 command, everything installs automatically
#  Usage: curl -fsSL https://raw.githubusercontent.com/YOUR/REPO/main/install.sh | bash
# ============================================================

# ---------- ANSI Colors ----------
RED='\033[0;31m';    GREEN='\033[0;32m';  YELLOW='\033[1;33m'
BLUE='\033[0;34m';   CYAN='\033[0;36m';  MAGENTA='\033[0;35m'
WHITE='\033[1;37m';  BOLD='\033[1m';     RESET='\033[0m'

# ---------- Installation directory ----------
INSTALL_DIR="$HOME/roblox-rejoin"
CONFIG_DIR="$INSTALL_DIR/config"
LOG_DIR="$INSTALL_DIR/logs"
LIB_DIR="$INSTALL_DIR/lib"
REPO_BASE="https://raw.githubusercontent.com/aryaramdd/rejoice/main"

# ---------- Banner ----------
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ██████╗  ██████╗ ██████╗ ██╗      ██████╗ ██╗  ██╗"
    echo "  ██╔══██╗██╔═══██╗██╔══██╗██║     ██╔═══██╗╚██╗██╔╝"
    echo "  ██████╔╝██║   ██║██████╔╝██║     ██║   ██║ ╚███╔╝ "
    echo "  ██╔══██╗██║   ██║██╔══██╗██║     ██║   ██║ ██╔██╗ "
    echo "  ██║  ██║╚██████╔╝██████╔╝███████╗╚██████╔╝██╔╝ ██╗"
    echo "  ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝"
    echo -e "${YELLOW}         ██████╗ ███████╗     ██╗ ██████╗ ██╗███╗   ██╗${RESET}"
    echo -e "${YELLOW}         ██╔══██╗██╔════╝     ██║██╔═══██╗██║████╗  ██║${RESET}"
    echo -e "${YELLOW}         ██████╔╝█████╗       ██║██║   ██║██║██╔██╗ ██║${RESET}"
    echo -e "${YELLOW}         ██╔══██╗██╔══╝  ██   ██║██║   ██║██║██║╚██╗██║${RESET}"
    echo -e "${YELLOW}         ██║  ██║███████╗╚█████╔╝╚██████╔╝██║██║ ╚████║${RESET}"
    echo -e "${YELLOW}         ╚═╝  ╚═╝╚══════╝ ╚════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝${RESET}"
    echo ""
    echo -e "${WHITE}        ╔══════════════════════════════════════╗${RESET}"
    echo -e "${WHITE}        ║   🎮  Auto Rejoin Tool  v2.0.0  🎮   ║${RESET}"
    echo -e "${WHITE}        ║      Made for Rooted Android          ║${RESET}"
    echo -e "${WHITE}        ╚══════════════════════════════════════╝${RESET}"
    echo ""
}

# ---------- Log helper ----------
log_info()    { echo -e "${GREEN}[✓]${RESET} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${RESET} $1"; }
log_error()   { echo -e "${RED}[✗]${RESET} $1"; }
log_step()    { echo -e "${CYAN}[→]${RESET} ${BOLD}$1${RESET}"; }

# ---------- Check root ----------
check_root() {
    log_step "Checking ROOT permission..."
    if ! su -c "echo ok" &>/dev/null; then
        log_error "Device is not ROOTED or Termux has not been granted su permission!"
        echo -e "${YELLOW}Guide: Open Magisk -> grant SuperUser permission to Termux${RESET}"
        exit 1
    fi
    log_info "Root OK!"
}

# ---------- Update & install packages ----------
install_dependencies() {
    log_step "Updating pkg repositories..."
    pkg update -y -o Dpkg::Options::="--force-confold" 2>/dev/null | tail -1

    log_step "Installing dependencies..."
    local deps=("curl" "git" "jq" "bc" "busybox" "termux-api" "ncurses-utils")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo -ne "  ${CYAN}Install ${dep}...${RESET}"
            if pkg install -y "$dep" &>/dev/null; then
                echo -e " ${GREEN}✓${RESET}"
            else
                echo -e " ${YELLOW}skipped (optional)${RESET}"
            fi
        else
            echo -e "  ${GREEN}✓${RESET} ${dep} already installed"
        fi
    done
}

# ---------- Creating directory structure ----------
create_directories() {
    log_step "Creating directory structure..."
    mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$LOG_DIR" "$LIB_DIR"
    log_info "Directory: $INSTALL_DIR"
}

# ---------- Download files from repo ----------
download_files() {
    log_step "Downloading script files..."

    # List of files to download
    declare -A FILES=(
        ["$INSTALL_DIR/main.sh"]="main.sh"
        ["$LIB_DIR/detect.sh"]="lib/detect.sh"
        ["$LIB_DIR/rejoin.sh"]="lib/rejoin.sh"
        ["$LIB_DIR/menu.sh"]="lib/menu.sh"
        ["$LIB_DIR/webhook.sh"]="lib/webhook.sh"
        ["$LIB_DIR/utils.sh"]="lib/utils.sh"
        ["$LIB_DIR/advanced.sh"]="lib/advanced.sh"
    )

    local success=true
    for dest in "${!FILES[@]}"; do
        local src="${FILES[$dest]}"
        echo -ne "  ${CYAN}Download ${src}...${RESET}"
        if curl -fsSL "$REPO_BASE/$src" -o "$dest" 2>/dev/null; then
            chmod +x "$dest"
            echo -e " ${GREEN}✓${RESET}"
        else
            echo -e " ${RED}FAILED${RESET}"
            success=false
        fi
    done

    # If download fails (repo not available), create inline
    if [ "$success" = false ]; then
        log_warn "Failed to download from repo -> creating integrated files..."
        create_inline_files
    fi
}

# ---------- Create default config ----------
create_default_config() {
    local config_file="$CONFIG_DIR/config.json"
    if [ ! -f "$config_file" ]; then
        log_step "Creating default config file..."
        cat > "$config_file" << 'EOFCONFIG'
{
  "version": "2.0.0",
  "packages": [
    {
      "name": "Official Roblox",
      "pkg": "com.roblox.client",
      "enabled": true
    },
    {
      "name": "Delta Executor",
      "pkg": "com.vng.njnj",
      "enabled": false
    },
    {
      "name": "Codex Executor",
      "pkg": "com.codex.client",
      "enabled": false
    }
  ],
  "active_package": "com.roblox.client",
  "game": {
    "place_id": "",
    "access_code": "",
    "is_private": false,
    "full_link": ""
  },
  "timing": {
    "check_interval": 5,
    "rejoin_delay": 8,
    "max_retries": 10,
    "retry_cooldown": 30
  },
  "detection": {
    "use_logcat": true,
    "use_activity": true,
    "use_cpu": true,
    "cpu_threshold": 5,
    "cpu_low_duration": 20
  },
  "webhook": {
    "enabled": false,
    "url": "",
    "notify_rejoin": true,
    "notify_crash": true,
    "notify_success": true,
    "username": "Roblox AutoRejoin",
    "avatar_url": "https://i.imgur.com/roblox.png"
  },
  "advanced": {
    "auto_clear_cache": false,
    "clear_cache_interval": 3600,
    "change_android_id": false,
    "auto_boot": false,
    "kill_on_start": true
  },
  "stats": {
    "total_rejoins": 0,
    "total_crashes": 0,
    "last_rejoin": "",
    "start_time": ""
  }
}
EOFCONFIG
        log_info "Config created at: $config_file"
    fi
}

# ---------- Create shortcut command ----------
create_shortcut() {
    log_step "Creating shortcut command..."

    # Create startup script in $PATH
    local shortcut="$PREFIX/bin/rblx"
    cat > "$shortcut" << EOFSHORTCUT
#!/data/data/com.termux/files/usr/bin/bash
exec bash "$INSTALL_DIR/main.sh" "\$@"
EOFSHORTCUT
    chmod +x "$shortcut"
    log_info "Shortcut created: just type 'rblx' to open the tool!"
}

# ---------- Create .bashrc alias ----------
setup_alias() {
    local bashrc="$HOME/.bashrc"
    if ! grep -q "roblox-rejoin" "$bashrc" 2>/dev/null; then
        echo "" >> "$bashrc"
        echo "# Roblox Auto Rejoin" >> "$bashrc"
        echo "alias rblx='bash $INSTALL_DIR/main.sh'" >> "$bashrc"
    fi
}

# ---------- Create inline files (fallback when repo not available) ----------
create_inline_files() {
    # Create lib/utils.sh
    cat > "$LIB_DIR/utils.sh" << 'EOFUTILS'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  UTILS - Shared utility functions
# ============================================================

# Colors
RED='\033[0;31m';    GREEN='\033[0;32m';  YELLOW='\033[1;33m'
BLUE='\033[0;34m';   CYAN='\033[0;36m';  MAGENTA='\033[0;35m'
WHITE='\033[1;37m';  BOLD='\033[1m';     DIM='\033[2m'; RESET='\033[0m'

INSTALL_DIR="$HOME/roblox-rejoin"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
LOG_FILE="$INSTALL_DIR/logs/rejoin_$(date +%Y%m%d).log"

# ---------- Logger ----------
log()      { echo -e "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
log_ok()   { log "${GREEN}[OK]${RESET}   $1"; }
log_warn() { log "${YELLOW}[WARN]${RESET} $1"; }
log_err()  { log "${RED}[ERR]${RESET}  $1"; }
log_info() { log "${CYAN}[INFO]${RESET} $1"; }

# ---------- Read config ----------
get_config() {
    # $1 = path json (vd: .active_package)
    jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null
}

# ---------- Write config ----------
set_config() {
    # $1 = path, $2 = value
    local tmp=$(mktemp)
    jq "$1 = $2" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
}

# ---------- Update stats ----------
update_stat() {
    local field=$1 val=$2
    set_config ".stats.$field" "\"$val\""
}

increment_stat() {
    local field=$1
    local cur=$(get_config ".stats.$field // 0")
    set_config ".stats.$field" "$((cur + 1))"
}

# ---------- Small banner ----------
print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║  ${WHITE}${BOLD}🎮 Roblox Auto Rejoin v2.0  ${RESET}${CYAN}              ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${RESET}"
}

# ---------- Spinner animation ----------
spinner() {
    local pid=$1 msg=${2:-"Processing..."}
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}[${spin:$i:1}]${RESET} %s" "$msg"
        i=$(( (i+1) % ${#spin} ))
        sleep 0.1
    done
    printf "\r"
}

# ---------- Check internet ----------
check_internet() {
    curl -s --max-time 5 "https://8.8.8.8" &>/dev/null
}

# ---------- Get system info ----------
get_cpu_usage() {
    # Get total CPU usage (%)
    top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0"
}

get_ram_info() {
    local total=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
    local free=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}')
    local used=$((total - free))
    echo "${used}MB / ${total}MB"
}

get_uptime() {
    local start_time=$(get_config ".stats.start_time")
    if [ -z "$start_time" ]; then echo "N/A"; return; fi
    local now=$(date +%s)
    local diff=$((now - start_time))
    printf '%02dh:%02dm:%02ds' $((diff/3600)) $(((diff%3600)/60)) $((diff%60))
}

# ---------- Nice separator ----------
line() { echo -e "${DIM}────────────────────────────────────────────${RESET}"; }
EOFUTILS

    # Create lib/detect.sh
    cat > "$LIB_DIR/detect.sh" << 'EOFDETECT'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  DETECT - System to detect "no longer in server"
#  Combines multiple methods to minimize false positives
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh"

# Status tracking variable
CPU_LOW_COUNTER=0
LAST_ACTIVITY=""
DETECT_RUNNING=false

# ---------- Method 1: Check top activity ----------
# If Roblox is not top activity -> at home screen or crashed
check_activity() {
    local pkg=$1
    # dumpsys activity: get current top activity
    local top_activity=$(su -c "dumpsys activity activities 2>/dev/null" | \
        grep -E "mCurrentFocus|mFocusedActivity" | head -1 | \
        grep -o "[a-zA-Z0-9._]*/[a-zA-Z0-9._]*" | head -1)

    if echo "$top_activity" | grep -q "$pkg"; then
        echo "foreground"
    else
        echo "background"
    fi
}

# ---------- Method 2: Check running process ----------
check_process() {
    local pkg=$1
    # Check PID of package
    local pid=$(su -c "pidof $pkg 2>/dev/null || ps -A 2>/dev/null | grep $pkg | grep -v grep | awk '{print \$1}' | head -1")
    if [ -n "$pid" ] && [ "$pid" -gt 0 ] 2>/dev/null; then
        echo "running:$pid"
    else
        echo "dead"
    fi
}

# ---------- Method 3: Logcat monitoring ----------
# Detect keywords indicating disconnect/error
check_logcat() {
    local pkg=$1
    # Keywords indicating kicked/disconnected
    local keywords="Disconnected|ErrorPrompt|Connection failed|Kicked|Teleport failed|Game closed|Rejoining|LostConnection|PlaceId mismatch"

    # Get last 3 seconds of logcat for package
    local result=$(su -c "timeout 2 logcat -d -t 50 2>/dev/null" | \
        grep -E "$keywords" | tail -5)

    if [ -n "$result" ]; then
        log_warn "Logcat detected: $result"
        echo "disconnected"
    else
        echo "connected"
    fi
}

# ---------- Method 4: CPU usage monitoring ----------
# If CPU stays abnormally low -> app is idle/home
check_cpu_for_pkg() {
    local pkg=$1
    local threshold=$(get_config ".detection.cpu_threshold // 5")
    local max_low=$(get_config ".detection.cpu_low_duration // 20")

    local pid=$(su -c "pidof $pkg 2>/dev/null" | awk '{print $1}')
    if [ -z "$pid" ]; then echo "no_process"; return; fi

    # Read CPU usage of specific process
    local cpu=$(su -c "cat /proc/$pid/stat 2>/dev/null" | awk '{print ($14+$15)}')
    # Simple comparison - if < threshold continuously -> idle
    if [ "${cpu:-0}" -lt "$threshold" ] 2>/dev/null; then
        CPU_LOW_COUNTER=$((CPU_LOW_COUNTER + 1))
    else
        CPU_LOW_COUNTER=0
    fi

    if [ "$CPU_LOW_COUNTER" -ge "$max_low" ]; then
        echo "idle_too_long"
    else
        echo "active"
    fi
}

# ---------- Method 5: Check if screen is on ----------
check_screen() {
    local state=$(su -c "dumpsys power 2>/dev/null | grep 'mWakefulness'" | \
        grep -o "Awake\|Asleep\|Dozing" | head -1)
    echo "${state:-Unknown}"
}

# ---------- MASTER DETECT: Combine all methods ----------
detect_need_rejoin() {
    local pkg=$1
    local use_logcat=$(get_config ".detection.use_logcat // true")
    local use_activity=$(get_config ".detection.use_activity // true")
    local use_cpu=$(get_config ".detection.use_cpu // true")

    local score=0          # Accumulate "need rejoin" score
    local reasons=()

    # --- Check if process exists ---
    local proc_status=$(check_process "$pkg")
    if [ "$proc_status" = "dead" ]; then
        log_warn "Process $pkg is dead!"
        echo "rejoin:process_dead"
        return
    fi

    # --- Check activity (high priority) ---
    if [ "$use_activity" = "true" ]; then
        local act=$(check_activity "$pkg")
        if [ "$act" = "background" ]; then
            score=$((score + 3))
            reasons+=("app_background")
        fi
    fi

    # --- Check logcat ---
    if [ "$use_logcat" = "true" ]; then
        local lcat=$(check_logcat "$pkg")
        if [ "$lcat" = "disconnected" ]; then
            score=$((score + 5))
            reasons+=("logcat_disconnect")
        fi
    fi

    # --- Check CPU ---
    if [ "$use_cpu" = "true" ]; then
        local cpu_stat=$(check_cpu_for_pkg "$pkg")
        if [ "$cpu_stat" = "idle_too_long" ]; then
            score=$((score + 2))
            reasons+=("cpu_idle")
        fi
    fi

    # --- Decision ---
    if [ "$score" -ge 3 ]; then
        local reason_str=$(IFS='+'; echo "${reasons[*]}")
        echo "rejoin:$reason_str"
    else
        echo "ok"
    fi
}
EOFDETECT

    # Create lib/rejoin.sh
    cat > "$LIB_DIR/rejoin.sh" << 'EOFREJOIN'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  REJOIN - Execute game rejoin
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh"
source "$HOME/roblox-rejoin/lib/webhook.sh"

# ---------- Kill Roblox app ----------
kill_roblox() {
    local pkg=$1
    log_info "Killing $pkg..."
    su -c "am force-stop $pkg 2>/dev/null"
    sleep 1
    # Kill fallback by PID
    local pid=$(su -c "pidof $pkg 2>/dev/null")
    [ -n "$pid" ] && su -c "kill -9 $pid 2>/dev/null"
    sleep 1
    log_ok "Killed $pkg"
}

# ---------- Clear Roblox cache ----------
clear_roblox_cache() {
    local pkg=$1
    log_info "Clearing cache $pkg..."
    su -c "pm clear $pkg 2>/dev/null" && log_ok "Cache cleared"
}

# ---------- Build deep link to join game ----------
build_deeplink() {
    local place_id=$(get_config ".game.place_id")
    local access_code=$(get_config ".game.access_code")
    local is_private=$(get_config ".game.is_private")
    local full_link=$(get_config ".game.full_link")

    # If full link (vip link) exists -> parse
    if [ -n "$full_link" ] && [ "$full_link" != "null" ]; then
        # Extract from URL format: https://www.roblox.com/games/PLACEID?privateServerLinkCode=CODE
        place_id=$(echo "$full_link" | grep -oE '/games/[0-9]+' | grep -oE '[0-9]+')
        access_code=$(echo "$full_link" | grep -oE 'privateServerLinkCode=[^&]+' | cut -d= -f2)
        is_private="true"
    fi

    if [ -z "$place_id" ]; then
        log_err "Place ID not configured!"
        return 1
    fi

    # Build link
    if [ "$is_private" = "true" ] && [ -n "$access_code" ]; then
        echo "roblox://placeId=${place_id}&accessCode=${access_code}"
    else
        echo "roblox://placeId=${place_id}"
    fi
}

# ---------- Open app via deep link (priority) ----------
rejoin_deeplink() {
    local pkg=$1
    local deeplink=$(build_deeplink)
    [ $? -ne 0 ] && return 1

    log_info "Rejoin via deep link: $deeplink"
    su -c "am start -a android.intent.action.VIEW -d '$deeplink' -p '$pkg' --activity-clear-task 2>/dev/null"
    return $?
}

# ---------- Fallback: Open app activity directly ----------
rejoin_direct() {
    local pkg=$1
    log_warn "Fallback: open app $pkg directly..."
    # Get main activity of package
    local main_activity=$(su -c "pm dump $pkg 2>/dev/null | grep 'android.intent.action.MAIN' -A2 | grep 'Activity:' | head -1 | awk '{print \$2}'")

    if [ -n "$main_activity" ]; then
        su -c "am start -n '$main_activity' 2>/dev/null"
    else
        su -c "monkey -p $pkg -c android.intent.category.LAUNCHER 1 2>/dev/null"
    fi
}

# ---------- MASTER REJOIN FUNCTION ----------
do_rejoin() {
    local pkg=$1
    local reason=${2:-"unknown"}
    local max_retries=$(get_config ".timing.max_retries // 10")
    local rejoin_delay=$(get_config ".timing.rejoin_delay // 8")
    local attempt=0

    log_warn "🔄 REJOIN STARTED | Reason: $reason | Package: $pkg"
    send_webhook_rejoin "$pkg" "$reason"
    increment_stat "total_rejoins"
    update_stat "last_rejoin" "$(date '+%Y-%m-%d %H:%M:%S')"

    while [ $attempt -lt $max_retries ]; do
        attempt=$((attempt + 1))
        log_info "Attempt $attempt/$max_retries..."

        # Step 1: Kill app
        kill_roblox "$pkg"

        # Step 2: Wait
        log_info "Waiting ${rejoin_delay}s before rejoining..."
        sleep "$rejoin_delay"

        # Step 3: Try deep link
        if rejoin_deeplink "$pkg"; then
            sleep 5
            # Check if app is running
            local pid=$(su -c "pidof $pkg 2>/dev/null")
            if [ -n "$pid" ]; then
                log_ok "✅ Rejoin successful! PID: $pid"
                send_webhook_success "$pkg" "$attempt"
                return 0
            fi
        fi

        # Step 4: Fallback
        rejoin_direct "$pkg"
        sleep 5

        local pid=$(su -c "pidof $pkg 2>/dev/null")
        if [ -n "$pid" ]; then
            log_ok "✅ Rejoin successful (fallback)! PID: $pid"
            send_webhook_success "$pkg" "$attempt"
            return 0
        fi

        local cooldown=$(get_config ".timing.retry_cooldown // 30")
        log_warn "Failed attempt $attempt, waiting ${cooldown}s..."
        sleep "$cooldown"
    done

    log_err "❌ Rejoin failed after $max_retries attempts!"
    send_webhook_crash "$pkg"
    increment_stat "total_crashes"
    return 1
}
EOFREJOIN

    # Create lib/webhook.sh
    cat > "$LIB_DIR/webhook.sh" << 'EOFWEBHOOK'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  WEBHOOK - Send Discord notification
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh" 2>/dev/null

# ---------- Send Discord embed ----------
send_discord() {
    local title=$1 description=$2 color=${3:-"3447003"} footer=$4

    local webhook_url=$(get_config ".webhook.url")
    local enabled=$(get_config ".webhook.enabled")
    local username=$(get_config ".webhook.username // \"Roblox AutoRejoin\"")
    local avatar=$(get_config ".webhook.avatar_url // \"\"")

    [ "$enabled" != "true" ] && return
    [ -z "$webhook_url" ] || [ "$webhook_url" = "null" ] && return

    local payload=$(jq -n \
        --arg username "$username" \
        --arg avatar "$avatar" \
        --arg title "$title" \
        --arg desc "$description" \
        --argjson color "$color" \
        --arg footer "${footer:-$(date '+%Y-%m-%d %H:%M:%S')}" \
        '{
            username: $username,
            avatar_url: $avatar,
            embeds: [{
                title: $title,
                description: $desc,
                color: $color,
                footer: { text: $footer },
                timestamp: (now | todate)
            }]
        }')

    curl -s -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -d "$payload" &>/dev/null &
}

send_webhook_rejoin() {
    local pkg=$1 reason=$2
    local notify=$(get_config ".webhook.notify_rejoin")
    [ "$notify" != "true" ] && return
    send_discord \
        "🔄 Auto Rejoin Triggered" \
        "**Package:** \`$pkg\`\n**Reason:** $reason\n**Time:** $(date '+%H:%M:%S')" \
        "16776960"  # Yellow
}

send_webhook_success() {
    local pkg=$1 attempt=$2
    local notify=$(get_config ".webhook.notify_success")
    [ "$notify" != "true" ] && return
    send_discord \
        "✅ Rejoin Successful" \
        "**Package:** \`$pkg\`\n**Attempt:** $attempt\n**Time:** $(date '+%H:%M:%S')" \
        "3066993"  # Green
}

send_webhook_crash() {
    local pkg=$1
    local notify=$(get_config ".webhook.notify_crash")
    [ "$notify" != "true" ] && return
    send_discord \
        "❌ Rejoin Failed" \
        "**Package:** \`$pkg\`\n**Exhausted all retries!**\n**Time:** $(date '+%H:%M:%S')" \
        "15158332"  # Red
}
EOFWEBHOOK

    # Create lib/advanced.sh
    cat > "$LIB_DIR/advanced.sh" << 'EOFADVANCED'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ADVANCED - Advanced features
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh"

# ---------- Clear cache for all Roblox packages ----------
adv_clear_all_cache() {
    echo -e "${YELLOW}Clearing cache for all Roblox packages...${RESET}"
    local packages=$(jq -r '.packages[].pkg' "$CONFIG_FILE")
    while IFS= read -r pkg; do
        echo -ne "  Clear cache $pkg..."
        su -c "pm clear $pkg 2>/dev/null" && echo -e " ${GREEN}✓${RESET}" || echo -e " ${RED}✗${RESET}"
    done <<< "$packages"
}

# ---------- Kill all Roblox ----------
adv_kill_all() {
    echo -e "${YELLOW}Kill all Roblox packages...${RESET}"
    local packages=$(jq -r '.packages[].pkg' "$CONFIG_FILE")
    while IFS= read -r pkg; do
        su -c "am force-stop $pkg 2>/dev/null"
        echo -e "  ${RED}Killed:${RESET} $pkg"
    done <<< "$packages"
}

# ---------- Change Android ID (avoid ban) ----------
adv_change_android_id() {
    echo -e "${YELLOW}⚠ Changing Android ID will affect some other apps!${RESET}"
    echo -ne "Confirm? (y/N): "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && return

    # Generate random 16-char hex ID
    local new_id=$(cat /dev/urandom | tr -dc 'a-f0-9' | head -c 16)
    su -c "settings put secure android_id $new_id 2>/dev/null"
    echo -e "${GREEN}New Android ID: $new_id${RESET}"
    log_ok "Changed Android ID: $new_id"
}

# ---------- View/Delete log ----------
adv_view_logs() {
    local log_dir="$INSTALL_DIR/logs"
    local logs=($(ls -t "$log_dir"/*.log 2>/dev/null))

    if [ ${#logs[@]} -eq 0 ]; then
        echo -e "${YELLOW}No logs yet.${RESET}"
        return
    fi

    echo -e "${CYAN}Log files:${RESET}"
    for i in "${!logs[@]}"; do
        echo "  $((i+1)). $(basename ${logs[$i]}) ($(du -sh ${logs[$i]} | cut -f1))"
    done

    echo -ne "\nSelect log (1-${#logs[@]}) or Enter to cancel: "
    read -r choice
    [ -z "$choice" ] && return

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#logs[@]}" ]; then
        tail -50 "${logs[$((choice-1))]}" | less
    fi
}

adv_clear_logs() {
    rm -f "$INSTALL_DIR/logs/"*.log
    echo -e "${GREEN}Deleted all log files${RESET}"
}

# ---------- Check installed Roblox version ----------
adv_show_packages_info() {
    echo -e "${CYAN}Roblox packages info:${RESET}"
    line
    local packages=$(jq -r '.packages[] | "\(.pkg)|\(.name)"' "$CONFIG_FILE")
    while IFS='|' read -r pkg name; do
        local version=$(su -c "pm dump $pkg 2>/dev/null | grep versionName | head -1 | awk -F= '{print \$2}'" 2>/dev/null)
        local status="❌ Not installed"
        [ -n "$version" ] && status="✅ v$version"
        printf "  %-30s %-20s %s\n" "$name" "$pkg" "$status"
    done <<< "$packages"
    line
}

# ---------- Advanced Menu ----------
menu_advanced() {
    while true; do
        clear
        print_header
        echo -e "\n${BOLD}  ⚙ ADVANCED SETTINGS${RESET}\n"
        echo "  1. 🗑  Clear cache for all Roblox"
        echo "  2. 💀 Kill all Roblox"
        echo "  3. 🔀 Change Android ID"
        echo "  4. 📋 View log files"
        echo "  5. 🗑  Clear all logs"
        echo "  6. 📦 Installed packages info"
        echo "  7. ↩  Back"
        line
        echo -ne "${CYAN}Select: ${RESET}"
        read -r choice

        case $choice in
            1) adv_clear_all_cache; read -rp "Press Enter to continue..." ;;
            2) adv_kill_all; read -rp "Press Enter to continue..." ;;
            3) adv_change_android_id; read -rp "Press Enter to continue..." ;;
            4) adv_view_logs ;;
            5) adv_clear_logs; read -rp "Press Enter to continue..." ;;
            6) adv_show_packages_info; read -rp "Press Enter to continue..." ;;
            7) break ;;
            *) echo -e "${RED}Invalid selection!${RESET}"; sleep 1 ;;
        esac
    done
}
EOFADVANCED

    # Create lib/menu.sh
    cat > "$LIB_DIR/menu.sh" << 'EOFMENU'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  MENU - Main menu interface
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh"
source "$HOME/roblox-rejoin/lib/advanced.sh"

# ---------- Package management menu ----------
menu_packages() {
    while true; do
        clear
        print_header
        echo -e "\n${BOLD}  📦 MANAGE PACKAGE${RESET}\n"

        # Show current packages
        local i=1
        local active=$(get_config ".active_package")
        echo -e "  ${DIM}Current packages:${RESET}"
        line
        while IFS='|' read -r pkg name enabled; do
            local mark="${RED}○${RESET}"
            [ "$enabled" = "true" ] && mark="${GREEN}●${RESET}"
            [ "$pkg" = "$active" ] && mark="${YELLOW}★${RESET}"
            printf "  ${mark} %d. %-25s %s\n" "$i" "$name" "$pkg"
            i=$((i+1))
        done < <(jq -r '.packages[] | "\(.pkg)|\(.name)|\(.enabled)"' "$CONFIG_FILE")
        line
        echo "  ${YELLOW}★${RESET} = Active  ${GREEN}●${RESET} = Enabled  ${RED}○${RESET} = Disabled"
        echo ""
        echo "  A. Add new package"
        echo "  S. Select active package"
        echo "  D. Delete package"
        echo "  T. Toggle enable/disable"
        echo "  B. Back"
        line
        echo -ne "${CYAN}Select: ${RESET}"
        read -r choice

        case ${choice,,} in
            a)
                echo -ne "Display name (e.g. Delta Executor): "
                read -r name
                echo -ne "Package name (e.g. com.vng.njnj): "
                read -r pkg
                # Add to config
                local tmp=$(mktemp)
                jq ".packages += [{\"name\":\"$name\",\"pkg\":\"$pkg\",\"enabled\":true}]" \
                    "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
                echo -e "${GREEN}Added: $name ($pkg)${RESET}"
                sleep 1
                ;;
            s)
                echo -ne "Enter package number to select: "
                read -r num
                local new_pkg=$(jq -r ".packages[$((num-1))].pkg // empty" "$CONFIG_FILE")
                if [ -n "$new_pkg" ]; then
                    set_config ".active_package" "\"$new_pkg\""
                    echo -e "${GREEN}Selected: $new_pkg${RESET}"
                else
                    echo -e "${RED}Invalid number!${RESET}"
                fi
                sleep 1
                ;;
            d)
                echo -ne "Enter package number to delete: "
                read -r num
                local tmp=$(mktemp)
                jq "del(.packages[$((num-1))])" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
                echo -e "${GREEN}Deleted!${RESET}"
                sleep 1
                ;;
            t)
                echo -ne "Enter package number: "
                read -r num
                local cur=$(jq -r ".packages[$((num-1))].enabled" "$CONFIG_FILE")
                local new_val="true"
                [ "$cur" = "true" ] && new_val="false"
                local tmp=$(mktemp)
                jq ".packages[$((num-1))].enabled = $new_val" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
                echo -e "${GREEN}Toggled: $new_val${RESET}"
                sleep 1
                ;;
            b) break ;;
        esac
    done
}

# ---------- Game config menu ----------
menu_game_config() {
    clear
    print_header
    echo -e "\n${BOLD}  🎮 CONFIG GAME${RESET}\n"

    local cur_pid=$(get_config ".game.place_id")
    local cur_code=$(get_config ".game.access_code")
    local cur_private=$(get_config ".game.is_private")
    local cur_link=$(get_config ".game.full_link")

    echo -e "  Current config:"
    echo -e "  Place ID: ${CYAN}${cur_pid:-not set}${RESET}"
    echo -e "  Private:  ${CYAN}$cur_private${RESET}"
    echo -e "  VIP Link: ${CYAN}${cur_link:-not set}${RESET}"
    line
    echo ""
    echo "  1. Enter Place ID (public game)"
    echo "  2. Enter VIP/Private Server Link"
    echo "  3. Clear game config"
    echo "  4. Back"
    line
    echo -ne "${CYAN}Select: ${RESET}"
    read -r choice

    case $choice in
        1)
            echo -ne "Enter Place ID: "
            read -r pid
            set_config ".game.place_id" "\"$pid\""
            set_config ".game.is_private" "false"
            set_config ".game.full_link" "null"
            set_config ".game.access_code" "null"
            echo -e "${GREEN}Saved Place ID: $pid${RESET}"
            ;;
        2)
            echo -e "${DIM}Example: https://www.roblox.com/games/12345678?privateServerLinkCode=XXXXX${RESET}"
            echo -ne "Enter VIP link: "
            read -r link
            # Parse link
            local pid=$(echo "$link" | grep -oE '/games/[0-9]+' | grep -oE '[0-9]+')
            local code=$(echo "$link" | grep -oE 'privateServerLinkCode=[^&]+' | cut -d= -f2)
            set_config ".game.full_link" "\"$link\""
            set_config ".game.place_id" "\"$pid\""
            set_config ".game.access_code" "\"$code\""
            set_config ".game.is_private" "true"
            echo -e "${GREEN}Saved VIP server: Place $pid${RESET}"
            ;;
        3)
            set_config ".game.place_id" "null"
            set_config ".game.access_code" "null"
            set_config ".game.full_link" "null"
            set_config ".game.is_private" "false"
            echo -e "${GREEN}Cleared game config${RESET}"
            ;;
    esac
    sleep 1
}

# ---------- Webhook menu ----------
menu_webhook() {
    clear
    print_header
    echo -e "\n${BOLD}  🔔 DISCORD WEBHOOK${RESET}\n"

    local cur_url=$(get_config ".webhook.url")
    local cur_enabled=$(get_config ".webhook.enabled")
    echo -e "  Webhook URL: ${CYAN}${cur_url:-not set}${RESET}"
    echo -e "  Status: $([ "$cur_enabled" = "true" ] && echo "${GREEN}ON${RESET}" || echo "${RED}OFF${RESET}")"
    line
    echo "  1. Set Webhook URL"
    echo "  2. Toggle on/off"
    echo "  3. Set notify_rejoin ($(get_config '.webhook.notify_rejoin'))"
    echo "  4. Set notify_crash ($(get_config '.webhook.notify_crash'))"
    echo "  5. Test webhook"
    echo "  6. Back"
    line
    echo -ne "${CYAN}Select: ${RESET}"
    read -r choice

    case $choice in
        1)
            echo -ne "Paste Webhook URL: "
            read -r url
            set_config ".webhook.url" "\"$url\""
            set_config ".webhook.enabled" "true"
            echo -e "${GREEN}Saved!${RESET}"
            ;;
        2)
            local cur=$(get_config ".webhook.enabled")
            [ "$cur" = "true" ] && set_config ".webhook.enabled" "false" || set_config ".webhook.enabled" "true"
            echo -e "${GREEN}Toggled!${RESET}"
            ;;
        3)
            local cur=$(get_config ".webhook.notify_rejoin")
            [ "$cur" = "true" ] && set_config ".webhook.notify_rejoin" "false" || set_config ".webhook.notify_rejoin" "true"
            ;;
        4)
            local cur=$(get_config ".webhook.notify_crash")
            [ "$cur" = "true" ] && set_config ".webhook.notify_crash" "false" || set_config ".webhook.notify_crash" "true"
            ;;
        5)
            source "$HOME/roblox-rejoin/lib/webhook.sh"
            send_discord "🧪 Test Webhook" "Connection successful from Roblox AutoRejoin!" "3066993"
            echo -e "${GREEN}Test message sent!${RESET}"
            ;;
    esac
    sleep 1
}

# ---------- Show status ----------
show_status() {
    clear
    print_header
    echo -e "\n${BOLD}  📊 STATUS${RESET}\n"

    local active_pkg=$(get_config ".active_package")
    local place_id=$(get_config ".game.place_id")
    local is_private=$(get_config ".game.is_private")
    local total_rejoins=$(get_config ".stats.total_rejoins // 0")
    local total_crashes=$(get_config ".stats.total_crashes // 0")
    local last_rejoin=$(get_config ".stats.last_rejoin // \"none\"")
    local ram=$(get_ram_info)
    local uptime=$(get_uptime)
    local webhook_enabled=$(get_config ".webhook.enabled")

    echo -e "  ${CYAN}Active package:${RESET}  $active_pkg"
    echo -e "  ${CYAN}Place ID:${RESET}        ${place_id:-not set}"
    echo -e "  ${CYAN}Private server:${RESET}  $is_private"
    line
    echo -e "  ${CYAN}RAM:${RESET}             $ram"
    echo -e "  ${CYAN}Uptime:${RESET}          $uptime"
    line
    echo -e "  ${GREEN}Total rejoins:${RESET}     $total_rejoins"
    echo -e "  ${RED}Total crashes:${RESET}      $total_crashes"
    echo -e "  ${CYAN}Last rejoin:${RESET}     $last_rejoin"
    line
    echo -e "  ${CYAN}Webhook:${RESET}         $([ "$webhook_enabled" = "true" ] && echo "${GREEN}ON${RESET}" || echo "${RED}OFF${RESET}")"
    line

    # Check if Roblox is running
    local pid=$(su -c "pidof $active_pkg 2>/dev/null")
    if [ -n "$pid" ]; then
        echo -e "  ${GREEN}● Roblox is running${RESET} (PID: $pid)"
    else
        echo -e "  ${RED}● Roblox not running${RESET}"
    fi

    echo ""
    read -rp "  Press Enter to go back..."
}
EOFMENU

    chmod +x "$LIB_DIR"/*.sh
    log_ok "All lib files have been created!"
}

# ---------- Done ----------
print_done() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║      ✅  INSTALLATION COMPLETED SUCCESSFULLY!      ║${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  Directory: ${CYAN}$INSTALL_DIR${RESET}"
    echo -e "  ⚙  Config:  ${CYAN}$CONFIG_DIR/config.json${RESET}"
    echo -e "  📝 Logs:    ${CYAN}$LOG_DIR${RESET}"
    echo ""
    echo -e "  ${BOLD}HOW TO USE:${RESET}"
    echo -e "  ${YELLOW}▶  Type 'rblx' or 'bash $INSTALL_DIR/main.sh'${RESET}"
    echo ""
    echo -e "  ${DIM}Next steps:${RESET}"
    echo "  1. Type 'rblx' to open the tool"
    echo "  2. Menu 1: Select your Roblox package"
    echo "  3. Menu 2: Enter Place ID or VIP link"
    echo "  4. Menu 3: Enable Auto Rejoin"
    echo ""
}

# ============================================================
#  MAIN INSTALLER
# ============================================================
main_install() {
    print_banner
    echo -e "${WHITE}Starting Roblox Auto Rejoin installation...${RESET}\n"

    check_root
    install_dependencies
    create_directories
    download_files
    create_default_config
    create_shortcut
    setup_alias
    print_done

    # Ask to run immediately (use /dev/tty when piped via curl | bash)
    echo -ne "${CYAN}Open tool now? (y/N): ${RESET}"
    read -r run_now </dev/tty 2>/dev/null || read -r run_now
    if [ "${run_now,,}" = "y" ]; then
        exec bash "$INSTALL_DIR/main.sh"
    fi
}

main_install
