#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ADVANCED.SH - Advanced features
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh" 2>/dev/null

# ============================================================
#  CLEAR CACHE FOR ALL PACKAGES
# ============================================================
adv_clear_all_cache() {
    echo ""
    echo -e "${YELLOW}  Clearing cache for Roblox packages...${RESET}"
    line

    while IFS='|' read -r pkg name; do
        echo -ne "  ${CYAN}$name${RESET} ($pkg) ... "
        local cleared=false
        for cache_dir in \
            "/data/data/$pkg/cache" \
            "/data/data/$pkg/code_cache" \
            "/sdcard/Android/data/$pkg/cache"
        do
            if su -c "[ -d '$cache_dir' ]" </dev/null 2>/dev/null; then
                su -c "rm -rf '$cache_dir'/* 2>/dev/null" </dev/null
                cleared=true
            fi
        done

        if $cleared; then
            echo -e "${GREEN}Done${RESET}"
        else
            echo -e "${DIM}no cache${RESET}"
        fi
    done < <(jq -r '.packages[] | "\(.pkg)|\(.name)"' "$CONFIG_FILE" 2>/dev/null)
}

# ============================================================
#  KILL ALL ROBLOX PACKAGES
# ============================================================
adv_kill_all() {
    echo ""
    echo -e "${YELLOW}  Killing all Roblox packages...${RESET}"
    line

    while IFS='|' read -r pkg name; do
        echo -ne "  ${CYAN}$name${RESET} ... "
        su -c "am force-stop '$pkg' 2>/dev/null" </dev/null
        local pid; pid=$(su -c "pidof '$pkg' 2>/dev/null" </dev/null | awk '{print $1}')
        [ -n "$pid" ] && su -c "kill -9 $pid 2>/dev/null" </dev/null
        echo -e "${RED}killed${RESET}"
    done < <(jq -r '.packages[] | "\(.pkg)|\(.name)"' "$CONFIG_FILE" 2>/dev/null)
}

# ============================================================
#  CHANGE ANDROID ID
# ============================================================
adv_change_android_id() {
    echo ""
    echo -e "${YELLOW}  WARNING: Change Android ID${RESET}"
    echo "  Android ID is the unique identifier of the device."
    echo "  Changing it may affect: Google Play, other apps, licenses..."
    line

    if ! confirm "Are you sure you want to change Android ID?"; then
        echo -e "  ${DIM}Cancelled.${RESET}"
        return
    fi

    local current_id; current_id=$(su -c "settings get secure android_id 2>/dev/null" </dev/null)
    echo -e "  Current ID: ${DIM}$current_id${RESET}"

    local new_id; new_id=$(cat /dev/urandom | tr -dc 'a-f0-9' | head -c 16 2>/dev/null)

    if su -c "settings put secure android_id '$new_id' 2>/dev/null" </dev/null; then
        local verify; verify=$(su -c "settings get secure android_id 2>/dev/null" </dev/null)
        if [ "$verify" = "$new_id" ]; then
            echo -e "  ${GREEN}New Android ID: $new_id${RESET}"
            log_ok "Changed Android ID: $current_id -> $new_id"
        else
            echo -e "  ${YELLOW}Set but reboot required to apply${RESET}"
        fi
    else
        echo -e "  ${RED}Failed! Requires higher root permission.${RESET}"
    fi
}

# ============================================================
#  VIEW LOG
# ============================================================
adv_view_logs() {
    local log_dir="$INSTALL_DIR/logs"
    mapfile -t logs < <(ls -t "$log_dir"/*.log 2>/dev/null)

    if [ ${#logs[@]} -eq 0 ]; then
        echo ""
        echo -e "  ${YELLOW}No logs yet.${RESET}"
        press_enter; return
    fi

    echo ""
    echo -e "  ${CYAN}Log files:${RESET}"
    line
    for i in "${!logs[@]}"; do
        local size; size=$(du -sh "${logs[$i]}" 2>/dev/null | cut -f1)
        printf "  %2d. %-35s %s\n" "$((i+1))" "$(basename "${logs[$i]}")" "${size:-?}"
    done
    line

    echo -ne "  Select log (1-${#logs[@]}) or Enter to cancel: "
    read -r choice </dev/tty
    [ -z "$choice" ] && return

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#logs[@]}" ]; then
        local file="${logs[$((choice-1))]}"
        echo -e "${DIM}  -- Last 100 lines: $(basename "$file") --${RESET}"
        tail -100 "$file" | more
    else
        echo -e "  ${RED}Invalid number!${RESET}"
    fi
    press_enter
}

adv_clear_logs() {
    if confirm "Delete all log files?"; then
        rm -f "$LOG_DIR"/*.log
        echo -e "  ${GREEN}Deleted all log files${RESET}"
    fi
    sleep 1
}

# ============================================================
#  INSTALLED PACKAGES INFO
# ============================================================
adv_show_packages_info() {
    echo ""
    echo -e "  ${CYAN}Roblox packages info:${RESET}"
    line
    printf "  %-18s %-30s %-12s %s\n" "Name" "Package" "Version" "Status"
    line

    while IFS='|' read -r pkg name; do
        local version
        version=$(su -c "pm dump '$pkg' 2>/dev/null | grep 'versionName=' | head -1 | cut -d= -f2" </dev/null 2>/dev/null)
        local status_str
        if [ -n "$version" ] && [ "$version" != "null" ]; then
            status_str="${GREEN}Installed${RESET}"
        else
            status_str="${RED}Not installed${RESET}"
            version="N/A"
        fi
        printf "  %-18s %-30s %-12s " "$name" "$pkg" "v${version}"
        echo -e "$status_str"
    done < <(jq -r '.packages[] | "\(.pkg)|\(.name)"' "$CONFIG_FILE" 2>/dev/null)
    line
    press_enter
}

# ============================================================
#  FIND PACKAGE NAME OF RUNNING APP
# ============================================================
adv_find_package() {
    echo ""
    echo -e "  ${CYAN}Finding package name of foreground app...${RESET}"
    echo "  Open Roblox/executor app first, then press Enter."
    press_enter

    local pkg
    pkg=$(su -c "dumpsys activity activities 2>/dev/null | grep mCurrentFocus | grep -oE '[a-zA-Z0-9.]+/[a-zA-Z0-9._]+' | head -1 | cut -d/ -f1" </dev/null 2>/dev/null)

    if [ -n "$pkg" ]; then
        echo -e "\n  ${GREEN}Found package: ${BOLD}$pkg${RESET}"
        if confirm "Add this package to the list?"; then
            echo -ne "  Enter display name: "
            read -r name </dev/tty
            local tmp; tmp=$(mktemp)
            jq ".packages += [{\"name\":\"${name:-Unknown}\",\"pkg\":\"$pkg\",\"enabled\":true}]" \
                "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
            echo -e "  ${GREEN}Added!${RESET}"
        fi
    else
        echo -e "  ${RED}Package not found. Make sure app is in foreground!${RESET}"
    fi
    press_enter
}

# ============================================================
#  AUTO BOOT CONFIG
# ============================================================
adv_setup_autoboot() {
    local bashrc="$HOME/.bashrc"
    local boot_line="# RblxAutoRejoin autoboot"

    if grep -q "$boot_line" "$bashrc" 2>/dev/null; then
        echo -e "  ${YELLOW}Auto boot is ON.${RESET}"
        if confirm "Disable auto boot?"; then
            sed -i "/$boot_line/,+2d" "$bashrc"
            set_config ".advanced.auto_boot" "false"
            echo -e "  ${GREEN}Auto boot disabled.${RESET}"
        fi
    else
        echo -e "  Auto boot is OFF."
        echo "  When enabled, tool will auto-run whenever Termux opens."
        if confirm "Enable auto boot?"; then
            cat >> "$bashrc" << EOFBOOT

$boot_line
if [ -f "$INSTALL_DIR/main.sh" ]; then
    bash "$INSTALL_DIR/main.sh" start &>/dev/null &
fi
EOFBOOT
            set_config ".advanced.auto_boot" "true"
            echo -e "  ${GREEN}Auto boot enabled!${RESET}"
        fi
    fi
    press_enter
}

# ============================================================
#  ADVANCED MENU
# ============================================================
menu_advanced() {
    while true; do
        clear
        print_header
        echo ""
        echo -e "  ${BOLD}ADVANCED SETTINGS${RESET}"
        echo ""
        echo "  1. Clear cache for all Roblox"
        echo "  2. Kill all Roblox"
        echo "  3. Change Android ID"
        echo "  4. View log files"
        echo "  5. Clear all logs"
        echo "  6. Installed packages info"
        echo "  7. Find package name of running app"
        echo "  8. Setup Auto Boot"
        echo "  9. Back"
        line
        echo -ne "${CYAN}  Select: ${RESET}"
        read -r choice </dev/tty

        case $choice in
            1) adv_clear_all_cache; press_enter ;;
            2) adv_kill_all; press_enter ;;
            3) adv_change_android_id; press_enter ;;
            4) adv_view_logs ;;
            5) adv_clear_logs ;;
            6) adv_show_packages_info ;;
            7) adv_find_package ;;
            8) adv_setup_autoboot ;;
            9) break ;;
            *) echo -e "${RED}  Invalid selection!${RESET}"; sleep 0.8 ;;
        esac
    done
}
