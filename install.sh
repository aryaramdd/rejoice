#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  TERMUX ROBLOX AUTO REJOIN - ONE-COMMAND INSTALLER
#  Chỉ cần paste 1 lệnh, mọi thứ tự động cài đặt
#  Usage: curl -fsSL https://raw.githubusercontent.com/YOUR/REPO/main/install.sh | bash
# ============================================================

# ---------- ANSI Colors ----------
RED='\033[0;31m';    GREEN='\033[0;32m';  YELLOW='\033[1;33m'
BLUE='\033[0;34m';   CYAN='\033[0;36m';  MAGENTA='\033[0;35m'
WHITE='\033[1;37m';  BOLD='\033[1m';     RESET='\033[0m'

# ---------- Thư mục cài đặt ----------
INSTALL_DIR="$HOME/roblox-rejoin"
CONFIG_DIR="$INSTALL_DIR/config"
LOG_DIR="$INSTALL_DIR/logs"
LIB_DIR="$INSTALL_DIR/lib"
REPO_BASE="https://raw.githubusercontent.com/Vyfuyu/Roblox-Rejoinerv10/main"

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

# ---------- Kiểm tra root ----------
check_root() {
    log_step "Kiểm tra quyền ROOT..."
    if ! su -c "echo ok" &>/dev/null; then
        log_error "Thiết bị chưa ROOT hoặc Termux chưa được cấp quyền su!"
        echo -e "${YELLOW}Hướng dẫn: Mở Magisk → cấp phép SuperUser cho Termux${RESET}"
        exit 1
    fi
    log_info "Root OK!"
}

# ---------- Cập nhật & cài packages ----------
install_dependencies() {
    log_step "Cập nhật pkg repositories..."
    pkg update -y -o Dpkg::Options::="--force-confold" 2>/dev/null | tail -1

    log_step "Cài đặt dependencies..."
    local deps=("curl" "git" "jq" "bc" "busybox" "termux-api" "ncurses-utils")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo -ne "  ${CYAN}Cài ${dep}...${RESET}"
            if pkg install -y "$dep" &>/dev/null; then
                echo -e " ${GREEN}✓${RESET}"
            else
                echo -e " ${YELLOW}bỏ qua (không bắt buộc)${RESET}"
            fi
        else
            echo -e "  ${GREEN}✓${RESET} ${dep} đã có"
        fi
    done
}

# ---------- Tạo cấu trúc thư mục ----------
create_directories() {
    log_step "Tạo cấu trúc thư mục..."
    mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$LOG_DIR" "$LIB_DIR"
    log_info "Thư mục: $INSTALL_DIR"
}

# ---------- Download files từ repo ----------
download_files() {
    log_step "Tải script files..."

    # Danh sách files cần download
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
        echo -ne "  ${CYAN}Tải ${src}...${RESET}"
        if curl -fsSL "$REPO_BASE/$src" -o "$dest" 2>/dev/null; then
            chmod +x "$dest"
            echo -e " ${GREEN}✓${RESET}"
        else
            echo -e " ${RED}FAILED${RESET}"
            success=false
        fi
    done

    # Nếu không download được (chưa có repo), tạo inline
    if [ "$success" = false ]; then
        log_warn "Không tải được từ repo → tạo files tích hợp..."
        create_inline_files
    fi
}

# ---------- Tạo config mẫu ----------
create_default_config() {
    local config_file="$CONFIG_DIR/config.json"
    if [ ! -f "$config_file" ]; then
        log_step "Tạo file config mặc định..."
        cat > "$config_file" << 'EOFCONFIG'
{
  "version": "2.0.0",
  "packages": [
    {
      "name": "Roblox Gốc",
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
        log_info "Config tạo tại: $config_file"
    fi
}

# ---------- Tạo shortcut lệnh ----------
create_shortcut() {
    log_step "Tạo lệnh shortcut..."

    # Tạo script khởi động trong $PATH
    local shortcut="$PREFIX/bin/rblx"
    cat > "$shortcut" << EOFSHORTCUT
#!/data/data/com.termux/files/usr/bin/bash
exec bash "$INSTALL_DIR/main.sh" "\$@"
EOFSHORTCUT
    chmod +x "$shortcut"
    log_info "Shortcut tạo: bây giờ chỉ cần gõ 'rblx' để mở tool!"
}

# ---------- Tạo .bashrc alias ----------
setup_alias() {
    local bashrc="$HOME/.bashrc"
    if ! grep -q "roblox-rejoin" "$bashrc" 2>/dev/null; then
        echo "" >> "$bashrc"
        echo "# Roblox Auto Rejoin" >> "$bashrc"
        echo "alias rblx='bash $INSTALL_DIR/main.sh'" >> "$bashrc"
    fi
}

# ---------- Tạo inline files (fallback khi không có repo) ----------
create_inline_files() {
    # Tạo lib/utils.sh
    cat > "$LIB_DIR/utils.sh" << 'EOFUTILS'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  UTILS - Các hàm tiện ích dùng chung
# ============================================================

# Màu sắc
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

# ---------- Đọc config ----------
get_config() {
    # $1 = path json (vd: .active_package)
    jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null
}

# ---------- Ghi config ----------
set_config() {
    # $1 = path, $2 = value
    local tmp=$(mktemp)
    jq "$1 = $2" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
}

# ---------- Cập nhật stats ----------
update_stat() {
    local field=$1 val=$2
    set_config ".stats.$field" "\"$val\""
}

increment_stat() {
    local field=$1
    local cur=$(get_config ".stats.$field // 0")
    set_config ".stats.$field" "$((cur + 1))"
}

# ---------- Banner nhỏ ----------
print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║  ${WHITE}${BOLD}🎮 Roblox Auto Rejoin v2.0  ${RESET}${CYAN}              ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${RESET}"
}

# ---------- Spinner animation ----------
spinner() {
    local pid=$1 msg=${2:-"Đang xử lý..."}
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}[${spin:$i:1}]${RESET} %s" "$msg"
        i=$(( (i+1) % ${#spin} ))
        sleep 0.1
    done
    printf "\r"
}

# ---------- Kiểm tra internet ----------
check_internet() {
    curl -s --max-time 5 "https://8.8.8.8" &>/dev/null
}

# ---------- Lấy thông tin hệ thống ----------
get_cpu_usage() {
    # Lấy CPU usage tổng (%)
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

# ---------- Separator đẹp ----------
line() { echo -e "${DIM}────────────────────────────────────────────${RESET}"; }
EOFUTILS

    # Tạo lib/detect.sh
    cat > "$LIB_DIR/detect.sh" << 'EOFDETECT'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  DETECT - Hệ thống phát hiện "không còn trong server"
#  Kết hợp đa phương pháp để giảm false positive
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh"

# Biến theo dõi trạng thái
CPU_LOW_COUNTER=0
LAST_ACTIVITY=""
DETECT_RUNNING=false

# ---------- Phương pháp 1: Kiểm tra top activity ----------
# Nếu Roblox không phải top activity → đang ở màn home hoặc crash
check_activity() {
    local pkg=$1
    # dumpsys activity: lấy top activity hiện tại
    local top_activity=$(su -c "dumpsys activity activities 2>/dev/null" | \
        grep -E "mCurrentFocus|mFocusedActivity" | head -1 | \
        grep -o "[a-zA-Z0-9._]*/[a-zA-Z0-9._]*" | head -1)

    if echo "$top_activity" | grep -q "$pkg"; then
        echo "foreground"
    else
        echo "background"
    fi
}

# ---------- Phương pháp 2: Kiểm tra process đang chạy ----------
check_process() {
    local pkg=$1
    # Kiểm tra PID của package
    local pid=$(su -c "pidof $pkg 2>/dev/null || ps -A 2>/dev/null | grep $pkg | grep -v grep | awk '{print \$1}' | head -1")
    if [ -n "$pid" ] && [ "$pid" -gt 0 ] 2>/dev/null; then
        echo "running:$pid"
    else
        echo "dead"
    fi
}

# ---------- Phương pháp 3: Logcat monitoring ----------
# Phát hiện keywords báo hiệu disconnect/error
check_logcat() {
    local pkg=$1
    # Các keyword báo hiệu đã bị kick/disconnect
    local keywords="Disconnected|ErrorPrompt|Connection failed|Kicked|Teleport failed|Game closed|Rejoining|LostConnection|PlaceId mismatch"

    # Lấy logcat 3 giây gần nhất của package
    local result=$(su -c "timeout 2 logcat -d -t 50 2>/dev/null" | \
        grep -E "$keywords" | tail -5)

    if [ -n "$result" ]; then
        log_warn "Logcat phát hiện: $result"
        echo "disconnected"
    else
        echo "connected"
    fi
}

# ---------- Phương pháp 4: CPU usage monitoring ----------
# Nếu CPU thấp bất thường lâu → app đang ở idle/home
check_cpu_for_pkg() {
    local pkg=$1
    local threshold=$(get_config ".detection.cpu_threshold // 5")
    local max_low=$(get_config ".detection.cpu_low_duration // 20")

    local pid=$(su -c "pidof $pkg 2>/dev/null" | awk '{print $1}')
    if [ -z "$pid" ]; then echo "no_process"; return; fi

    # Đọc CPU usage của process cụ thể
    local cpu=$(su -c "cat /proc/$pid/stat 2>/dev/null" | awk '{print ($14+$15)}')
    # So sánh đơn giản — nếu < threshold liên tục → idle
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

# ---------- Phương pháp 5: Kiểm tra màn hình có sáng không ----------
check_screen() {
    local state=$(su -c "dumpsys power 2>/dev/null | grep 'mWakefulness'" | \
        grep -o "Awake\|Asleep\|Dozing" | head -1)
    echo "${state:-Unknown}"
}

# ---------- MASTER DETECT: Tổng hợp tất cả phương pháp ----------
detect_need_rejoin() {
    local pkg=$1
    local use_logcat=$(get_config ".detection.use_logcat // true")
    local use_activity=$(get_config ".detection.use_activity // true")
    local use_cpu=$(get_config ".detection.use_cpu // true")

    local score=0          # Tích lũy điểm "cần rejoin"
    local reasons=()

    # --- Kiểm tra process tồn tại ---
    local proc_status=$(check_process "$pkg")
    if [ "$proc_status" = "dead" ]; then
        log_warn "Process $pkg đã chết!"
        echo "rejoin:process_dead"
        return
    fi

    # --- Kiểm tra activity (ưu tiên cao) ---
    if [ "$use_activity" = "true" ]; then
        local act=$(check_activity "$pkg")
        if [ "$act" = "background" ]; then
            score=$((score + 3))
            reasons+=("app_background")
        fi
    fi

    # --- Kiểm tra logcat ---
    if [ "$use_logcat" = "true" ]; then
        local lcat=$(check_logcat "$pkg")
        if [ "$lcat" = "disconnected" ]; then
            score=$((score + 5))
            reasons+=("logcat_disconnect")
        fi
    fi

    # --- Kiểm tra CPU ---
    if [ "$use_cpu" = "true" ]; then
        local cpu_stat=$(check_cpu_for_pkg "$pkg")
        if [ "$cpu_stat" = "idle_too_long" ]; then
            score=$((score + 2))
            reasons+=("cpu_idle")
        fi
    fi

    # --- Quyết định ---
    if [ "$score" -ge 3 ]; then
        local reason_str=$(IFS='+'; echo "${reasons[*]}")
        echo "rejoin:$reason_str"
    else
        echo "ok"
    fi
}
EOFDETECT

    # Tạo lib/rejoin.sh
    cat > "$LIB_DIR/rejoin.sh" << 'EOFREJOIN'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  REJOIN - Thực hiện rejoin game
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh"
source "$HOME/roblox-rejoin/lib/webhook.sh"

# ---------- Kill Roblox app ----------
kill_roblox() {
    local pkg=$1
    log_info "Đang kill $pkg..."
    su -c "am force-stop $pkg 2>/dev/null"
    sleep 1
    # Kill fallback bằng PID
    local pid=$(su -c "pidof $pkg 2>/dev/null")
    [ -n "$pid" ] && su -c "kill -9 $pid 2>/dev/null"
    sleep 1
    log_ok "Đã kill $pkg"
}

# ---------- Xoá cache Roblox ----------
clear_roblox_cache() {
    local pkg=$1
    log_info "Đang xoá cache $pkg..."
    su -c "pm clear $pkg 2>/dev/null" && log_ok "Cache đã xoá"
}

# ---------- Build deep link để join game ----------
build_deeplink() {
    local place_id=$(get_config ".game.place_id")
    local access_code=$(get_config ".game.access_code")
    local is_private=$(get_config ".game.is_private")
    local full_link=$(get_config ".game.full_link")

    # Nếu có full link (vip link) → parse
    if [ -n "$full_link" ] && [ "$full_link" != "null" ]; then
        # Extract từ URL dạng: https://www.roblox.com/games/PLACEID?privateServerLinkCode=CODE
        place_id=$(echo "$full_link" | grep -oE '/games/[0-9]+' | grep -oE '[0-9]+')
        access_code=$(echo "$full_link" | grep -oE 'privateServerLinkCode=[^&]+' | cut -d= -f2)
        is_private="true"
    fi

    if [ -z "$place_id" ]; then
        log_err "Chưa cấu hình Place ID!"
        return 1
    fi

    # Build link
    if [ "$is_private" = "true" ] && [ -n "$access_code" ]; then
        echo "roblox://placeId=${place_id}&accessCode=${access_code}"
    else
        echo "roblox://placeId=${place_id}"
    fi
}

# ---------- Mở app bằng deep link (ưu tiên) ----------
rejoin_deeplink() {
    local pkg=$1
    local deeplink=$(build_deeplink)
    [ $? -ne 0 ] && return 1

    log_info "Rejoin bằng deep link: $deeplink"
    su -c "am start -a android.intent.action.VIEW -d '$deeplink' -p '$pkg' --activity-clear-task 2>/dev/null"
    return $?
}

# ---------- Fallback: Mở app activity trực tiếp ----------
rejoin_direct() {
    local pkg=$1
    log_warn "Fallback: mở app $pkg trực tiếp..."
    # Lấy main activity của package
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

    log_warn "🔄 BẮT ĐẦU REJOIN | Lý do: $reason | Package: $pkg"
    send_webhook_rejoin "$pkg" "$reason"
    increment_stat "total_rejoins"
    update_stat "last_rejoin" "$(date '+%Y-%m-%d %H:%M:%S')"

    while [ $attempt -lt $max_retries ]; do
        attempt=$((attempt + 1))
        log_info "Lần thử $attempt/$max_retries..."

        # Bước 1: Kill app
        kill_roblox "$pkg"

        # Bước 2: Đợi
        log_info "Đợi ${rejoin_delay}s trước khi rejoin..."
        sleep "$rejoin_delay"

        # Bước 3: Thử deep link
        if rejoin_deeplink "$pkg"; then
            sleep 5
            # Kiểm tra app có chạy không
            local pid=$(su -c "pidof $pkg 2>/dev/null")
            if [ -n "$pid" ]; then
                log_ok "✅ Rejoin thành công! PID: $pid"
                send_webhook_success "$pkg" "$attempt"
                return 0
            fi
        fi

        # Bước 4: Fallback
        rejoin_direct "$pkg"
        sleep 5

        local pid=$(su -c "pidof $pkg 2>/dev/null")
        if [ -n "$pid" ]; then
            log_ok "✅ Rejoin thành công (fallback)! PID: $pid"
            send_webhook_success "$pkg" "$attempt"
            return 0
        fi

        local cooldown=$(get_config ".timing.retry_cooldown // 30")
        log_warn "Thất bại lần $attempt, đợi ${cooldown}s..."
        sleep "$cooldown"
    done

    log_err "❌ Rejoin thất bại sau $max_retries lần thử!"
    send_webhook_crash "$pkg"
    increment_stat "total_crashes"
    return 1
}
EOFREJOIN

    # Tạo lib/webhook.sh
    cat > "$LIB_DIR/webhook.sh" << 'EOFWEBHOOK'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  WEBHOOK - Gửi thông báo Discord
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh" 2>/dev/null

# ---------- Gửi embed Discord ----------
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
        "**Package:** \`$pkg\`\n**Lý do:** $reason\n**Thời gian:** $(date '+%H:%M:%S')" \
        "16776960"  # Màu vàng
}

send_webhook_success() {
    local pkg=$1 attempt=$2
    local notify=$(get_config ".webhook.notify_success")
    [ "$notify" != "true" ] && return
    send_discord \
        "✅ Rejoin Thành Công" \
        "**Package:** \`$pkg\`\n**Lần thử:** $attempt\n**Thời gian:** $(date '+%H:%M:%S')" \
        "3066993"  # Màu xanh lá
}

send_webhook_crash() {
    local pkg=$1
    local notify=$(get_config ".webhook.notify_crash")
    [ "$notify" != "true" ] && return
    send_discord \
        "❌ Rejoin Thất Bại" \
        "**Package:** \`$pkg\`\n**Đã thử hết số lần tối đa!**\n**Thời gian:** $(date '+%H:%M:%S')" \
        "15158332"  # Màu đỏ
}
EOFWEBHOOK

    # Tạo lib/advanced.sh
    cat > "$LIB_DIR/advanced.sh" << 'EOFADVANCED'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ADVANCED - Tính năng nâng cao
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh"

# ---------- Xoá cache tất cả Roblox packages ----------
adv_clear_all_cache() {
    echo -e "${YELLOW}Đang xoá cache tất cả Roblox packages...${RESET}"
    local packages=$(jq -r '.packages[].pkg' "$CONFIG_FILE")
    while IFS= read -r pkg; do
        echo -ne "  Xoá cache $pkg..."
        su -c "pm clear $pkg 2>/dev/null" && echo -e " ${GREEN}✓${RESET}" || echo -e " ${RED}✗${RESET}"
    done <<< "$packages"
}

# ---------- Kill tất cả Roblox ----------
adv_kill_all() {
    echo -e "${YELLOW}Kill tất cả Roblox packages...${RESET}"
    local packages=$(jq -r '.packages[].pkg' "$CONFIG_FILE")
    while IFS= read -r pkg; do
        su -c "am force-stop $pkg 2>/dev/null"
        echo -e "  ${RED}Killed:${RESET} $pkg"
    done <<< "$packages"
}

# ---------- Đổi Android ID (tránh ban) ----------
adv_change_android_id() {
    echo -e "${YELLOW}⚠ Đổi Android ID sẽ ảnh hưởng đến một số app khác!${RESET}"
    echo -ne "Xác nhận? (y/N): "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && return

    # Tạo ID ngẫu nhiên 16 ký tự hex
    local new_id=$(cat /dev/urandom | tr -dc 'a-f0-9' | head -c 16)
    su -c "settings put secure android_id $new_id 2>/dev/null"
    echo -e "${GREEN}Android ID mới: $new_id${RESET}"
    log_ok "Đã đổi Android ID: $new_id"
}

# ---------- Xem/Xoá log ----------
adv_view_logs() {
    local log_dir="$INSTALL_DIR/logs"
    local logs=($(ls -t "$log_dir"/*.log 2>/dev/null))

    if [ ${#logs[@]} -eq 0 ]; then
        echo -e "${YELLOW}Chưa có log nào.${RESET}"
        return
    fi

    echo -e "${CYAN}Log files:${RESET}"
    for i in "${!logs[@]}"; do
        echo "  $((i+1)). $(basename ${logs[$i]}) ($(du -sh ${logs[$i]} | cut -f1))"
    done

    echo -ne "\nChọn log (1-${#logs[@]}) hoặc Enter để hủy: "
    read -r choice
    [ -z "$choice" ] && return

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#logs[@]}" ]; then
        tail -50 "${logs[$((choice-1))]}" | less
    fi
}

adv_clear_logs() {
    rm -f "$INSTALL_DIR/logs/"*.log
    echo -e "${GREEN}Đã xoá tất cả log files${RESET}"
}

# ---------- Kiểm tra phiên bản Roblox đang cài ----------
adv_show_packages_info() {
    echo -e "${CYAN}Thông tin các package Roblox:${RESET}"
    line
    local packages=$(jq -r '.packages[] | "\(.pkg)|\(.name)"' "$CONFIG_FILE")
    while IFS='|' read -r pkg name; do
        local version=$(su -c "pm dump $pkg 2>/dev/null | grep versionName | head -1 | awk -F= '{print \$2}'" 2>/dev/null)
        local status="❌ Chưa cài"
        [ -n "$version" ] && status="✅ v$version"
        printf "  %-30s %-20s %s\n" "$name" "$pkg" "$status"
    done <<< "$packages"
    line
}

# ---------- Menu Advanced ----------
menu_advanced() {
    while true; do
        clear
        print_header
        echo -e "\n${BOLD}  ⚙ ADVANCED SETTINGS${RESET}\n"
        echo "  1. 🗑  Xoá cache tất cả Roblox"
        echo "  2. 💀 Kill tất cả Roblox"
        echo "  3. 🔀 Đổi Android ID"
        echo "  4. 📋 Xem log files"
        echo "  5. 🗑  Xoá tất cả log"
        echo "  6. 📦 Thông tin packages đã cài"
        echo "  7. ↩  Quay lại"
        line
        echo -ne "${CYAN}Chọn: ${RESET}"
        read -r choice

        case $choice in
            1) adv_clear_all_cache; read -rp "Enter để tiếp tục..." ;;
            2) adv_kill_all; read -rp "Enter để tiếp tục..." ;;
            3) adv_change_android_id; read -rp "Enter để tiếp tục..." ;;
            4) adv_view_logs ;;
            5) adv_clear_logs; read -rp "Enter để tiếp tục..." ;;
            6) adv_show_packages_info; read -rp "Enter để tiếp tục..." ;;
            7) break ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ!${RESET}"; sleep 1 ;;
        esac
    done
}
EOFADVANCED

    # Tạo lib/menu.sh
    cat > "$LIB_DIR/menu.sh" << 'EOFMENU'
#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  MENU - Giao diện menu chính
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh"
source "$HOME/roblox-rejoin/lib/advanced.sh"

# ---------- Menu quản lý packages ----------
menu_packages() {
    while true; do
        clear
        print_header
        echo -e "\n${BOLD}  📦 QUẢN LÝ PACKAGE${RESET}\n"

        # Hiển thị packages hiện tại
        local i=1
        local active=$(get_config ".active_package")
        echo -e "  ${DIM}Packages hiện tại:${RESET}"
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
        echo "  A. Thêm package mới"
        echo "  S. Chọn package active"
        echo "  D. Xoá package"
        echo "  T. Toggle enable/disable"
        echo "  B. Quay lại"
        line
        echo -ne "${CYAN}Chọn: ${RESET}"
        read -r choice

        case ${choice,,} in
            a)
                echo -ne "Tên hiển thị (vd: Delta Executor): "
                read -r name
                echo -ne "Package name (vd: com.vng.njnj): "
                read -r pkg
                # Thêm vào config
                local tmp=$(mktemp)
                jq ".packages += [{\"name\":\"$name\",\"pkg\":\"$pkg\",\"enabled\":true}]" \
                    "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
                echo -e "${GREEN}Đã thêm: $name ($pkg)${RESET}"
                sleep 1
                ;;
            s)
                echo -ne "Nhập số thứ tự package muốn chọn: "
                read -r num
                local new_pkg=$(jq -r ".packages[$((num-1))].pkg // empty" "$CONFIG_FILE")
                if [ -n "$new_pkg" ]; then
                    set_config ".active_package" "\"$new_pkg\""
                    echo -e "${GREEN}Đã chọn: $new_pkg${RESET}"
                else
                    echo -e "${RED}Số không hợp lệ!${RESET}"
                fi
                sleep 1
                ;;
            d)
                echo -ne "Nhập số thứ tự package muốn xoá: "
                read -r num
                local tmp=$(mktemp)
                jq "del(.packages[$((num-1))])" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
                echo -e "${GREEN}Đã xoá!${RESET}"
                sleep 1
                ;;
            t)
                echo -ne "Nhập số thứ tự package: "
                read -r num
                local cur=$(jq -r ".packages[$((num-1))].enabled" "$CONFIG_FILE")
                local new_val="true"
                [ "$cur" = "true" ] && new_val="false"
                local tmp=$(mktemp)
                jq ".packages[$((num-1))].enabled = $new_val" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
                echo -e "${GREEN}Đã toggle: $new_val${RESET}"
                sleep 1
                ;;
            b) break ;;
        esac
    done
}

# ---------- Menu cấu hình game ----------
menu_game_config() {
    clear
    print_header
    echo -e "\n${BOLD}  🎮 CONFIG GAME${RESET}\n"

    local cur_pid=$(get_config ".game.place_id")
    local cur_code=$(get_config ".game.access_code")
    local cur_private=$(get_config ".game.is_private")
    local cur_link=$(get_config ".game.full_link")

    echo -e "  Config hiện tại:"
    echo -e "  Place ID: ${CYAN}${cur_pid:-chưa đặt}${RESET}"
    echo -e "  Private:  ${CYAN}$cur_private${RESET}"
    echo -e "  VIP Link: ${CYAN}${cur_link:-chưa đặt}${RESET}"
    line
    echo ""
    echo "  1. Nhập Place ID (public game)"
    echo "  2. Nhập VIP/Private Server Link"
    echo "  3. Xoá cấu hình game"
    echo "  4. Quay lại"
    line
    echo -ne "${CYAN}Chọn: ${RESET}"
    read -r choice

    case $choice in
        1)
            echo -ne "Nhập Place ID: "
            read -r pid
            set_config ".game.place_id" "\"$pid\""
            set_config ".game.is_private" "false"
            set_config ".game.full_link" "null"
            set_config ".game.access_code" "null"
            echo -e "${GREEN}Đã lưu Place ID: $pid${RESET}"
            ;;
        2)
            echo -e "${DIM}Ví dụ: https://www.roblox.com/games/12345678?privateServerLinkCode=XXXXX${RESET}"
            echo -ne "Nhập VIP link: "
            read -r link
            # Parse link
            local pid=$(echo "$link" | grep -oE '/games/[0-9]+' | grep -oE '[0-9]+')
            local code=$(echo "$link" | grep -oE 'privateServerLinkCode=[^&]+' | cut -d= -f2)
            set_config ".game.full_link" "\"$link\""
            set_config ".game.place_id" "\"$pid\""
            set_config ".game.access_code" "\"$code\""
            set_config ".game.is_private" "true"
            echo -e "${GREEN}Đã lưu VIP server: Place $pid${RESET}"
            ;;
        3)
            set_config ".game.place_id" "null"
            set_config ".game.access_code" "null"
            set_config ".game.full_link" "null"
            set_config ".game.is_private" "false"
            echo -e "${GREEN}Đã xoá config game${RESET}"
            ;;
    esac
    sleep 1
}

# ---------- Menu webhook ----------
menu_webhook() {
    clear
    print_header
    echo -e "\n${BOLD}  🔔 DISCORD WEBHOOK${RESET}\n"

    local cur_url=$(get_config ".webhook.url")
    local cur_enabled=$(get_config ".webhook.enabled")
    echo -e "  Webhook URL: ${CYAN}${cur_url:-chưa đặt}${RESET}"
    echo -e "  Trạng thái: $([ "$cur_enabled" = "true" ] && echo "${GREEN}BẬT${RESET}" || echo "${RED}TẮT${RESET}")"
    line
    echo "  1. Đặt Webhook URL"
    echo "  2. Toggle bật/tắt"
    echo "  3. Cài notify_rejoin ($(get_config '.webhook.notify_rejoin'))"
    echo "  4. Cài notify_crash ($(get_config '.webhook.notify_crash'))"
    echo "  5. Test webhook"
    echo "  6. Quay lại"
    line
    echo -ne "${CYAN}Chọn: ${RESET}"
    read -r choice

    case $choice in
        1)
            echo -ne "Paste Webhook URL: "
            read -r url
            set_config ".webhook.url" "\"$url\""
            set_config ".webhook.enabled" "true"
            echo -e "${GREEN}Đã lưu!${RESET}"
            ;;
        2)
            local cur=$(get_config ".webhook.enabled")
            [ "$cur" = "true" ] && set_config ".webhook.enabled" "false" || set_config ".webhook.enabled" "true"
            echo -e "${GREEN}Đã toggle!${RESET}"
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
            send_discord "🧪 Test Webhook" "Kết nối thành công từ Roblox AutoRejoin!" "3066993"
            echo -e "${GREEN}Đã gửi test message!${RESET}"
            ;;
    esac
    sleep 1
}

# ---------- Hiển thị status ----------
show_status() {
    clear
    print_header
    echo -e "\n${BOLD}  📊 STATUS${RESET}\n"

    local active_pkg=$(get_config ".active_package")
    local place_id=$(get_config ".game.place_id")
    local is_private=$(get_config ".game.is_private")
    local total_rejoins=$(get_config ".stats.total_rejoins // 0")
    local total_crashes=$(get_config ".stats.total_crashes // 0")
    local last_rejoin=$(get_config ".stats.last_rejoin // \"chưa có\"")
    local ram=$(get_ram_info)
    local uptime=$(get_uptime)
    local webhook_enabled=$(get_config ".webhook.enabled")

    echo -e "  ${CYAN}Package active:${RESET}  $active_pkg"
    echo -e "  ${CYAN}Place ID:${RESET}        ${place_id:-chưa đặt}"
    echo -e "  ${CYAN}Private server:${RESET}  $is_private"
    line
    echo -e "  ${CYAN}RAM:${RESET}             $ram"
    echo -e "  ${CYAN}Uptime:${RESET}          $uptime"
    line
    echo -e "  ${GREEN}Tổng rejoin:${RESET}     $total_rejoins"
    echo -e "  ${RED}Tổng crash:${RESET}      $total_crashes"
    echo -e "  ${CYAN}Rejoin cuối:${RESET}     $last_rejoin"
    line
    echo -e "  ${CYAN}Webhook:${RESET}         $([ "$webhook_enabled" = "true" ] && echo "${GREEN}BẬT${RESET}" || echo "${RED}TẮT${RESET}")"
    line

    # Kiểm tra Roblox đang chạy không
    local pid=$(su -c "pidof $active_pkg 2>/dev/null")
    if [ -n "$pid" ]; then
        echo -e "  ${GREEN}● Roblox đang chạy${RESET} (PID: $pid)"
    else
        echo -e "  ${RED}● Roblox không chạy${RESET}"
    fi

    echo ""
    read -rp "  Enter để quay lại..."
}
EOFMENU

    chmod +x "$LIB_DIR"/*.sh
    log_ok "Tất cả lib files đã được tạo!"
}

# ---------- Hoàn tất ----------
print_done() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║      ✅  CÀI ĐẶT HOÀN TẤT THÀNH CÔNG!      ║${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  📂 Thư mục: ${CYAN}$INSTALL_DIR${RESET}"
    echo -e "  ⚙  Config:  ${CYAN}$CONFIG_DIR/config.json${RESET}"
    echo -e "  📝 Logs:    ${CYAN}$LOG_DIR${RESET}"
    echo ""
    echo -e "  ${BOLD}CÁCH SỬ DỤNG:${RESET}"
    echo -e "  ${YELLOW}▶  Gõ 'rblx' hoặc 'bash $INSTALL_DIR/main.sh'${RESET}"
    echo ""
    echo -e "  ${DIM}Bước tiếp theo:${RESET}"
    echo "  1. Gõ 'rblx' để mở tool"
    echo "  2. Menu 1: Chọn package Roblox của bạn"
    echo "  3. Menu 2: Nhập Place ID hoặc VIP link"
    echo "  4. Menu 3: Bật Auto Rejoin"
    echo ""
}

# ============================================================
#  MAIN INSTALLER
# ============================================================
main_install() {
    print_banner
    echo -e "${WHITE}Bắt đầu cài đặt Roblox Auto Rejoin...${RESET}\n"

    check_root
    install_dependencies
    create_directories
    download_files
    create_default_config
    create_shortcut
    setup_alias
    print_done

    # Hỏi chạy ngay không
    echo -ne "${CYAN}Mở tool ngay bây giờ? (y/N): ${RESET}"
    read -r run_now
    if [ "${run_now,,}" = "y" ]; then
        exec bash "$INSTALL_DIR/main.sh"
    fi
}

main_install
