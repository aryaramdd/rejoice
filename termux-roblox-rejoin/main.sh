#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ROBLOX AUTO REJOIN - MAIN ENTRY POINT
#  Launch: bash main.sh  or  type 'rblx'
# ============================================================

INSTALL_DIR="$HOME/roblox-rejoin"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
LIB_DIR="$INSTALL_DIR/lib"
LOG_DIR="$INSTALL_DIR/logs"

# ---------- Load all libraries ----------
for lib in utils detect rejoin webhook menu advanced; do
    src="$LIB_DIR/${lib}.sh"
    if [ ! -f "$src" ]; then
        echo "[ERR] Missing file: $src"
        echo "Run install.sh again to fix!"
        exit 1
    fi
    source "$src"
done

# ---------- PID file to manage background process ----------
PID_FILE="$INSTALL_DIR/.rejoin.pid"
MONITOR_LOG="$LOG_DIR/monitor_$(date +%Y%m%d).log"

# ============================================================
#  MAIN AUTO REJOIN LOOP
# ============================================================
rejoin_loop() {
    local pkg=$1
    local check_interval; check_interval=$(get_config ".timing.check_interval // 5")

    log_ok "Auto Rejoin ON | Package: $pkg | Interval: ${check_interval}s"
    update_stat "start_time" "$(date +%s)"

    local auto_clear; auto_clear=$(get_config ".advanced.auto_clear_cache")
    local clear_interval; clear_interval=$(get_config ".advanced.clear_cache_interval // 3600")
    local last_clear; last_clear=$(date +%s)

    log_info "Starting game for the first time..."
    do_rejoin "$pkg" "initial_start"
    sleep "$check_interval"

    while true; do
        local now; now=$(date +%s)

        if [ "$auto_clear" = "true" ]; then
            local elapsed=$(( now - last_clear ))
            if [ "$elapsed" -ge "$clear_interval" ]; then
                log_info "Periodic auto clear cache..."
                su -c "pm clear $pkg 2>/dev/null" </dev/null
                last_clear=$now
            fi
        fi

        local status; status=$(detect_need_rejoin "$pkg")

        if [[ "$status" == rejoin:* ]]; then
            local reason="${status#rejoin:}"
            log_warn "Rejoin needed! Reason: $reason"
            do_rejoin "$pkg" "$reason"
        else
            local pid; pid=$(su -c "pidof '$pkg' 2>/dev/null" </dev/null | awk '{print $1}')
            log_info "Game OK | PID: ${pid:-?} | Next check in ${check_interval}s"
        fi

        sleep "$check_interval"
    done
}

# ---------- Start auto rejoin ----------
start_rejoin() {
    local pkg; pkg=$(get_config ".active_package")
    local place_id; place_id=$(get_config ".game.place_id")
    local full_link; full_link=$(get_config ".game.full_link")

    if [ -z "$pkg" ] || [ "$pkg" = "null" ]; then
        echo -e "${RED}[!] No package selected! Go to Menu 1 to select.${RESET}"
        sleep 2; return 1
    fi

    if { [ -z "$place_id" ] || [ "$place_id" = "null" ]; } && \
       { [ -z "$full_link" ] || [ "$full_link" = "null" ]; }; then
        echo -e "${RED}[!] Game not configured! Go to Menu 2 to enter Place ID.${RESET}"
        sleep 2; return 1
    fi

    if [ -f "$PID_FILE" ]; then
        local old_pid; old_pid=$(cat "$PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            echo -e "${YELLOW}[!] Auto Rejoin already running (PID: $old_pid)!${RESET}"
            echo -ne "Restart? (y/N): "
            read -r confirm </dev/tty
            [ "${confirm,,}" != "y" ] && return
            stop_rejoin
        fi
    fi

    echo -e "${GREEN}[->] Starting Auto Rejoin for: $pkg${RESET}"
    rejoin_loop "$pkg" >> "$MONITOR_LOG" 2>&1 &
    local bg_pid=$!
    echo "$bg_pid" > "$PID_FILE"
    echo -e "${GREEN}[OK] Running in background | PID: $bg_pid | Log: $MONITOR_LOG${RESET}"
    echo -e "${DIM}Use 'rblx log' to view realtime log${RESET}"
    sleep 2
}

# ---------- Stop auto rejoin ----------
stop_rejoin() {
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}[!] Auto Rejoin is not running.${RESET}"
        sleep 1; return
    fi

    local pid; pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        sleep 1
        kill -9 "$pid" 2>/dev/null
        rm -f "$PID_FILE"
        echo -e "${GREEN}[OK] Stopped Auto Rejoin (PID: $pid)${RESET}"
    else
        echo -e "${YELLOW}[!] Process not found, cleaning PID file...${RESET}"
        rm -f "$PID_FILE"
    fi
    sleep 1
}

# ---------- Check rejoin status ----------
get_rejoin_status() {
    if [ -f "$PID_FILE" ]; then
        local pid; pid=$(cat "$PID_FILE")
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

# ---------- Timing settings menu ----------
menu_timing() {
    while true; do
        clear
        print_header
        echo ""
        echo -e "  ${BOLD}TIMING SETTINGS${RESET}"
        echo ""

        local ci; ci=$(get_config ".timing.check_interval")
        local rd; rd=$(get_config ".timing.rejoin_delay")
        local mr; mr=$(get_config ".timing.max_retries")
        local rc; rc=$(get_config ".timing.retry_cooldown")

        echo -e "  Check interval:  ${CYAN}${ci}s${RESET}"
        echo -e "  Rejoin delay:    ${CYAN}${rd}s${RESET}"
        echo -e "  Max retries:     ${CYAN}${mr}${RESET}"
        echo -e "  Retry cooldown:  ${CYAN}${rc}s${RESET}"
        line
        echo "  1. Check Interval (current: ${ci}s, recommended: 3-10)"
        echo "  2. Rejoin Delay   (current: ${rd}s, recommended: 5-15)"
        echo "  3. Max Retries    (current: ${mr})"
        echo "  4. Retry Cooldown (current: ${rc}s)"
        echo "  5. Back"
        line
        echo -ne "${CYAN}  Select: ${RESET}"
        read -r choice </dev/tty

        case $choice in
            1) echo -ne "  Check interval (seconds): "; read -r v </dev/tty; set_config ".timing.check_interval" "$v" ;;
            2) echo -ne "  Rejoin delay (seconds): ";   read -r v </dev/tty; set_config ".timing.rejoin_delay" "$v" ;;
            3) echo -ne "  Max retries: ";            read -r v </dev/tty; set_config ".timing.max_retries" "$v" ;;
            4) echo -ne "  Retry cooldown (seconds): "; read -r v </dev/tty; set_config ".timing.retry_cooldown" "$v" ;;
            5) break ;;
        esac
        [ "$choice" != "5" ] && { echo -e "${GREEN}  Saved!${RESET}"; sleep 1; }
    done
}

# ---------- View realtime log ----------
view_monitor_log() {
    if [ -f "$MONITOR_LOG" ]; then
        echo -e "${DIM}  Press Ctrl+C to exit...${RESET}"
        tail -f "$MONITOR_LOG"
    else
        echo -e "${YELLOW}  No monitor log yet.${RESET}"
        sleep 2
    fi
}

# ============================================================
#  MAIN MENU
# ============================================================
main_menu() {
    while true; do
        clear

        # ── Banner ──
        echo -e "${CYAN}  =================================${RESET}"
        echo -e "${CYAN}  |  ROBLOX AUTO REJOIN  v2.0   |${RESET}"
        echo -e "${CYAN}  |    Termux Root Edition       |${RESET}"
        echo -e "${CYAN}  =================================${RESET}"
        echo ""

        # ── Status (su uses </dev/null to not consume stdin) ──
        local pkg; pkg=$(get_config ".active_package")
        local place; place=$(get_config ".game.place_id")
        local rejoin_st; rejoin_st=$(get_rejoin_status)

        # Only check pidof if pkg is valid
        local pkg_pid=""
        if [[ "$pkg" =~ ^[a-zA-Z0-9._]+$ ]]; then
            pkg_pid=$(su -c "pidof '$pkg' 2>/dev/null" </dev/null 2>/dev/null | awk '{print $1}')
        fi

        echo -e "  Package : ${CYAN}${pkg:-not selected}${RESET}"
        echo -e "  Place ID: ${CYAN}${place:-not set}${RESET}"

        echo -ne "  Roblox  : "
        if [ -n "$pkg_pid" ]; then
            echo -e "${GREEN}[RUNNING] PID $pkg_pid${RESET}"
        else
            echo -e "${RED}[STOPPED]${RESET}"
        fi

        echo -ne "  Monitor : "
        if [[ "$rejoin_st" == running:* ]]; then
            echo -e "${GREEN}[ON] PID ${rejoin_st#running:}${RESET}"
        else
            echo -e "${RED}[OFF]${RESET}"
        fi

        line
        echo "  1. Manage Roblox Package"
        echo "  2. Game Config (Place ID / VIP Link)"
        echo -e "  ${GREEN}3. Start Auto Rejoin${RESET}"
        echo -e "  ${RED}4. Stop Auto Rejoin${RESET}"
        echo "  5. View Status"
        echo "  6. Discord Webhook"
        echo "  7. Timing Settings"
        echo "  8. Advanced"
        echo "  9. View Monitor Log (realtime)"
        echo "  0. Exit"
        line
        echo -ne "${CYAN}  Select: ${RESET}"
        read -r choice </dev/tty

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
                if [[ "$(get_rejoin_status)" == running:* ]]; then
                    echo -ne "${YELLOW}  Auto Rejoin is running, still exit? (y/N): ${RESET}"
                    read -r ex </dev/tty
                    [ "${ex,,}" = "y" ] && break
                else
                    break
                fi
                ;;
            *) echo -e "${RED}  Invalid selection!${RESET}"; sleep 0.8 ;;
        esac
    done

    echo -e "${CYAN}  Goodbye! Monitor keeps running in background if enabled.${RESET}"
}

# ============================================================
#  STARTUP
# ============================================================
case "${1:-}" in
    start)   start_rejoin; exit ;;
    stop)    stop_rejoin; exit ;;
    status)  echo "$(get_rejoin_status)"; exit ;;
    log)     view_monitor_log; exit ;;
    *)       main_menu ;;
esac
