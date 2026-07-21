#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ROBLOX AUTO REJOIN - MAIN ENTRY POINT
#  Khởi chạy: bash main.sh  hoặc  gõ 'rblx'
# ============================================================

INSTALL_DIR="$HOME/roblox-rejoin"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
LIB_DIR="$INSTALL_DIR/lib"
LOG_DIR="$INSTALL_DIR/logs"

# ---------- Load tất cả libraries ----------
for lib in utils detect rejoin webhook menu advanced; do
    src="$LIB_DIR/${lib}.sh"
    if [ ! -f "$src" ]; then
        echo "[ERR] Thiếu file: $src"
        echo "Chạy lại install.sh để sửa!"
        exit 1
    fi
    source "$src"
done

# ---------- PID file để quản lý background process ----------
PID_FILE="$INSTALL_DIR/.rejoin.pid"
MONITOR_LOG="$LOG_DIR/monitor_$(date +%Y%m%d).log"

# ============================================================
#  VÒNG LẶP AUTO REJOIN CHÍNH
# ============================================================
rejoin_loop() {
    local pkg=$1
    local check_interval=$(get_config ".timing.check_interval // 5")

    log_ok "🚀 Auto Rejoin BẬT | Package: $pkg | Interval: ${check_interval}s"
    update_stat "start_time" "$(date +%s)"

    # Auto clear cache nếu được bật
    local auto_clear=$(get_config ".advanced.auto_clear_cache")
    local clear_interval=$(get_config ".advanced.clear_cache_interval // 3600")
    local last_clear=$(date +%s)

    # Mở game lần đầu
    log_info "Khởi động game lần đầu..."
    do_rejoin "$pkg" "initial_start"
    sleep "$check_interval"

    # Vòng lặp chính
    while true; do
        local now=$(date +%s)

        # Auto clear cache theo định kỳ
        if [ "$auto_clear" = "true" ]; then
            local elapsed=$((now - last_clear))
            if [ "$elapsed" -ge "$clear_interval" ]; then
                log_info "Auto clear cache định kỳ..."
                su -c "pm clear $pkg 2>/dev/null"
                last_clear=$now
            fi
        fi

        # Kiểm tra trạng thái game
        local status=$(detect_need_rejoin "$pkg")

        if [[ "$status" == rejoin:* ]]; then
            local reason="${status#rejoin:}"
            log_warn "⚠  Phát hiện cần rejoin! Lý do: $reason"
            do_rejoin "$pkg" "$reason"
        else
            # Game đang chạy bình thường
            local pid=$(su -c "pidof $pkg 2>/dev/null" | awk '{print $1}')
            log_info "✅ Game OK | PID: ${pid:-?} | Kiểm tra tiếp sau ${check_interval}s"
        fi

        sleep "$check_interval"
    done
}

# ---------- Bắt đầu auto rejoin (background) ----------
start_rejoin() {
    # Kiểm tra config
    local pkg=$(get_config ".active_package")
    local place_id=$(get_config ".game.place_id")
    local full_link=$(get_config ".game.full_link")

    if [ -z "$pkg" ] || [ "$pkg" = "null" ]; then
        echo -e "${RED}[!] Chưa chọn package! Vào Menu 1 để chọn.${RESET}"
        sleep 2; return 1
    fi

    if { [ -z "$place_id" ] || [ "$place_id" = "null" ]; } && \
       { [ -z "$full_link" ] || [ "$full_link" = "null" ]; }; then
        echo -e "${RED}[!] Chưa cấu hình game! Vào Menu 2 để nhập Place ID.${RESET}"
        sleep 2; return 1
    fi

    # Kiểm tra đã chạy chưa
    if [ -f "$PID_FILE" ]; then
        local old_pid=$(cat "$PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            echo -e "${YELLOW}[!] Auto Rejoin đang chạy (PID: $old_pid)!${RESET}"
            echo -ne "Khởi động lại? (y/N): "
            read -r confirm
            [ "${confirm,,}" != "y" ] && return
            stop_rejoin
        fi
    fi

    echo -e "${GREEN}[→] Bắt đầu Auto Rejoin cho: $pkg${RESET}"

    # Chạy background
    rejoin_loop "$pkg" >> "$MONITOR_LOG" 2>&1 &
    local bg_pid=$!
    echo "$bg_pid" > "$PID_FILE"
    echo -e "${GREEN}[✓] Đang chạy ngầm | PID: $bg_pid | Log: $MONITOR_LOG${RESET}"
    echo -e "${DIM}Dùng 'tail -f $MONITOR_LOG' để xem log realtime${RESET}"
    sleep 2
}

# ---------- Dừng auto rejoin ----------
stop_rejoin() {
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}[!] Auto Rejoin không chạy.${RESET}"
        sleep 1; return
    fi

    local pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        sleep 1
        kill -9 "$pid" 2>/dev/null
        rm -f "$PID_FILE"
        echo -e "${GREEN}[✓] Đã dừng Auto Rejoin (PID: $pid)${RESET}"
    else
        echo -e "${YELLOW}[!] Process không tồn tại, dọn PID file...${RESET}"
        rm -f "$PID_FILE"
    fi
    sleep 1
}

# ---------- Kiểm tra trạng thái rejoin ----------
get_rejoin_status() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "running:$pid"
        else
            rm -f "$PID_FILE"
            echo "stopped"
        fi
    else
        echo "stopped"
    fi
}

# ---------- Menu cài đặt timing ----------
menu_timing() {
    clear
    print_header
    echo -e "\n${BOLD}  ⏱ CÀI TIMING${RESET}\n"

    local ci=$(get_config ".timing.check_interval")
    local rd=$(get_config ".timing.rejoin_delay")
    local mr=$(get_config ".timing.max_retries")
    local rc=$(get_config ".timing.retry_cooldown")

    echo -e "  Check interval:   ${CYAN}${ci}s${RESET}   (thời gian giữa mỗi lần kiểm tra)"
    echo -e "  Rejoin delay:     ${CYAN}${rd}s${RESET}   (đợi trước khi rejoin)"
    echo -e "  Max retries:      ${CYAN}${mr}${RESET}    (số lần thử tối đa)"
    echo -e "  Retry cooldown:   ${CYAN}${rc}s${RESET}   (đợi giữa các lần thử thất bại)"
    line

    echo "  1. Đổi Check Interval (hiện: ${ci}s, khuyến nghị: 3-10)"
    echo "  2. Đổi Rejoin Delay (hiện: ${rd}s, khuyến nghị: 5-15)"
    echo "  3. Đổi Max Retries (hiện: ${mr})"
    echo "  4. Đổi Retry Cooldown (hiện: ${rc}s)"
    echo "  5. Quay lại"
    line
    echo -ne "${CYAN}Chọn: ${RESET}"
    read -r choice

    case $choice in
        1) echo -ne "Check interval (giây): "; read -r v; set_config ".timing.check_interval" "$v" ;;
        2) echo -ne "Rejoin delay (giây): ";   read -r v; set_config ".timing.rejoin_delay" "$v" ;;
        3) echo -ne "Max retries: ";            read -r v; set_config ".timing.max_retries" "$v" ;;
        4) echo -ne "Retry cooldown (giây): "; read -r v; set_config ".timing.retry_cooldown" "$v" ;;
    esac
    echo -e "${GREEN}Đã lưu!${RESET}"; sleep 1
}

# ---------- Xem log realtime ----------
view_monitor_log() {
    if [ -f "$MONITOR_LOG" ]; then
        echo -e "${DIM}Nhấn Ctrl+C để thoát...${RESET}"
        tail -f "$MONITOR_LOG"
    else
        echo -e "${YELLOW}Chưa có log monitor.${RESET}"
        sleep 2
    fi
}

# ============================================================
#  MENU CHÍNH
# ============================================================
main_menu() {
    while true; do
        clear

        # Banner
        echo -e "${CYAN}"
        echo "  ╔══════════════════════════════════════════════════╗"
        echo "  ║     🎮  ROBLOX AUTO REJOIN  v2.0  🎮            ║"
        echo "  ║          Termux Root Edition                     ║"
        echo "  ╚══════════════════════════════════════════════════╝"
        echo -e "${RESET}"

        # Trạng thái nhanh
        local pkg=$(get_config ".active_package // \"chưa chọn\"")
        local place=$(get_config ".game.place_id // \"chưa đặt\"")
        local rejoin_st=$(get_rejoin_status)
        local pkg_pid=$(su -c "pidof $pkg 2>/dev/null" | awk '{print $1}')

        echo -e "  Package:  ${CYAN}$pkg${RESET}"
        echo -e "  Place ID: ${CYAN}$place${RESET}"
        echo -ne "  Roblox:   "
        [ -n "$pkg_pid" ] && echo -e "${GREEN}● Đang chạy (PID: $pkg_pid)${RESET}" || echo -e "${RED}● Không chạy${RESET}"
        echo -ne "  Monitor:  "
        if [[ "$rejoin_st" == running:* ]]; then
            echo -e "${GREEN}● AUTO REJOIN BẬT (PID: ${rejoin_st#running:})${RESET}"
        else
            echo -e "${RED}● Đã tắt${RESET}"
        fi
        line

        echo -e "  ${BOLD}1.${RESET} 📦 Quản lý Package Roblox"
        echo -e "  ${BOLD}2.${RESET} 🎮 Config Game (Place ID / VIP Link)"
        echo -e "  ${BOLD}3.${RESET} ${GREEN}▶  Bắt đầu Auto Rejoin${RESET}"
        echo -e "  ${BOLD}4.${RESET} ${RED}■  Dừng Auto Rejoin${RESET}"
        echo -e "  ${BOLD}5.${RESET} 📊 Xem Status"
        echo -e "  ${BOLD}6.${RESET} 🔔 Webhook Discord"
        echo -e "  ${BOLD}7.${RESET} ⏱  Cài Timing"
        echo -e "  ${BOLD}8.${RESET} ⚙  Advanced"
        echo -e "  ${BOLD}9.${RESET} 📋 Xem Monitor Log (realtime)"
        echo -e "  ${BOLD}0.${RESET} 🚪 Thoát"
        line
        echo -e "  ${DIM}Tip: Gõ 'rblx' bất cứ lúc nào để mở lại menu${RESET}"
        line
        echo -ne "${CYAN}  ▶ Chọn: ${RESET}"
        read -r choice

        case $choice in
            1) menu_packages ;;
            2) menu_game_config ;;
            3) start_rejoin ;;
            4) stop_rejoin ;;
            5) show_status ;;
            6) menu_webhook ;;
            7) menu_timing ;;
            8) menu_advanced ;;
            9) view_monitor_log ;;
            0)
                # Hỏi có muốn keep monitor chạy không
                if [[ "$(get_rejoin_status)" == running:* ]]; then
                    echo -ne "${YELLOW}Auto Rejoin đang chạy, vẫn muốn thoát? (y/N): ${RESET}"
                    read -r ex
                    [ "${ex,,}" = "y" ] && break
                else
                    break
                fi
                ;;
            *) echo -e "${RED}  Lựa chọn không hợp lệ!${RESET}"; sleep 0.8 ;;
        esac
    done

    echo -e "${CYAN}Tạm biệt! Auto Rejoin vẫn chạy ngầm nếu đã bật.${RESET}"
}

# ============================================================
#  KHỞI ĐỘNG
# ============================================================

# Xử lý tham số dòng lệnh
case "${1:-}" in
    start)   start_rejoin; exit ;;
    stop)    stop_rejoin; exit ;;
    status)  echo "$(get_rejoin_status)"; exit ;;
    log)     view_monitor_log; exit ;;
    *)       main_menu ;;
esac
