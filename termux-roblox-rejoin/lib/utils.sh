#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  UTILS.SH - Hàm tiện ích dùng chung
# ============================================================

# ---------- ANSI Colors ----------
RED='\033[0;31m';    GREEN='\033[0;32m';  YELLOW='\033[1;33m'
BLUE='\033[0;34m';   CYAN='\033[0;36m';  MAGENTA='\033[0;35m'
WHITE='\033[1;37m';  BOLD='\033[1m';     DIM='\033[2m'; RESET='\033[0m'

# ---------- Paths ----------
INSTALL_DIR="$HOME/roblox-rejoin"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
LOG_DIR="$INSTALL_DIR/logs"
LOG_FILE="$LOG_DIR/rejoin_$(date +%Y%m%d).log"

# Đảm bảo log dir tồn tại
mkdir -p "$LOG_DIR" 2>/dev/null

# ============================================================
#  LOGGING
# ============================================================
log()      { local msg="[$(date '+%H:%M:%S')] $1"; echo -e "$msg" | tee -a "$LOG_FILE"; }
log_ok()   { log "${GREEN}[OK]${RESET}   $1"; }
log_warn() { log "${YELLOW}[WARN]${RESET} $1"; }
log_err()  { log "${RED}[ERR]${RESET}  $1"; }
log_info() { log "${CYAN}[INFO]${RESET} $1"; }

# ============================================================
#  CONFIG - Đọc/Ghi JSON
# ============================================================

# Đọc giá trị từ config.json
# Usage: get_config ".active_package"
get_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo ""
        return 1
    fi
    jq -r "${1} // empty" "$CONFIG_FILE" 2>/dev/null
}

# Ghi giá trị vào config.json
# Usage: set_config ".active_package" '"com.roblox.client"'
set_config() {
    local path=$1
    local value=$2
    local tmp
    tmp=$(mktemp) || return 1
    if jq "$path = $value" "$CONFIG_FILE" > "$tmp" 2>/dev/null; then
        mv "$tmp" "$CONFIG_FILE"
    else
        rm -f "$tmp"
        log_err "set_config thất bại: path=$path value=$value"
        return 1
    fi
}

# Cập nhật trường stats
update_stat() {
    local field=$1 val=$2
    set_config ".stats.$field" "\"$val\""
}

# Tăng số đếm trong stats
increment_stat() {
    local field=$1
    local cur
    cur=$(get_config ".stats.$field // 0")
    cur=$(echo "$cur" | tr -d '"')  # loại bỏ quotes nếu có
    set_config ".stats.$field" "$((cur + 1))"
}

# ============================================================
#  SYSTEM INFO
# ============================================================

# RAM đang dùng / tổng
get_ram_info() {
    local total free used
    total=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print int($2/1024)}')
    free=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print int($2/1024)}')
    used=$((total - free))
    echo "${used}MB / ${total}MB"
}

# Uptime của tool (từ thời điểm bắt đầu)
get_uptime() {
    local start_time
    start_time=$(get_config ".stats.start_time // 0")
    start_time=$(echo "$start_time" | tr -d '"')

    if [ -z "$start_time" ] || [ "$start_time" = "0" ] || [ "$start_time" = "null" ]; then
        echo "N/A"
        return
    fi

    local now diff
    now=$(date +%s)
    diff=$((now - start_time))
    printf '%02dh:%02dm:%02ds' $((diff/3600)) $(((diff%3600)/60)) $((diff%60))
}

# CPU load tổng hệ thống
get_system_cpu() {
    local cpu
    cpu=$(top -bn1 2>/dev/null | grep -E "^(%Cpu|Cpu)" | awk '{print $2}' | tr -d '%')
    echo "${cpu:-0}"
}

# ============================================================
#  UI HELPERS
# ============================================================

print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║  ${WHITE}${BOLD}🎮 Roblox Auto Rejoin v2.0.0 ${RESET}${CYAN}            ║${RESET}"
    echo -e "${CYAN}║  ${DIM}Termux Root Edition${RESET}${CYAN}                          ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${RESET}"
}

line() {
    echo -e "${DIM}  ──────────────────────────────────────────────${RESET}"
}

confirm() {
    local prompt=${1:-"Bạn có chắc không?"}
    echo -ne "${YELLOW}${prompt} (y/N): ${RESET}"
    read -r ans
    [ "${ans,,}" = "y" ]
}

press_enter() {
    echo -ne "\n  ${DIM}Nhấn Enter để tiếp tục...${RESET}"
    read -r
}

# ============================================================
#  SPINNER ANIMATION
# ============================================================
spinner() {
    local pid=$1
    local msg=${2:-"Đang xử lý..."}
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}${spin:$((i % ${#spin})):1}${RESET} %s" "$msg"
        i=$((i + 1))
        sleep 0.08
    done
    printf "\r%-40s\r" " "
}

# ============================================================
#  NETWORK CHECK
# ============================================================
check_internet() {
    curl -s --connect-timeout 5 --max-time 8 "https://dns.google" &>/dev/null
}
