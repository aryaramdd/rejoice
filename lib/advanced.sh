#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ADVANCED.SH - Tính năng nâng cao
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh" 2>/dev/null

# ============================================================
#  XOÁ CACHE TẤT CẢ PACKAGE
# ============================================================
adv_clear_all_cache() {
    echo ""
    echo -e "${YELLOW}  Dang xoa cache cac Roblox packages...${RESET}"
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
            echo -e "${DIM}khong co cache${RESET}"
        fi
    done < <(jq -r '.packages[] | "\(.pkg)|\(.name)"' "$CONFIG_FILE" 2>/dev/null)
}

# ============================================================
#  KILL TẤT CẢ ROBLOX PACKAGES
# ============================================================
adv_kill_all() {
    echo ""
    echo -e "${YELLOW}  Kill tat ca Roblox packages...${RESET}"
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
#  ĐỔI ANDROID ID
# ============================================================
adv_change_android_id() {
    echo ""
    echo -e "${YELLOW}  CANH BAO: Doi Android ID${RESET}"
    echo "  Android ID la dinh danh duy nhat cua thiet bi."
    echo "  Doi no co the anh huong: Google Play, apps khac, license..."
    line

    if ! confirm "Ban co chac muon doi Android ID?"; then
        echo -e "  ${DIM}Da huy.${RESET}"
        return
    fi

    local current_id; current_id=$(su -c "settings get secure android_id 2>/dev/null" </dev/null)
    echo -e "  ID hien tai: ${DIM}$current_id${RESET}"

    local new_id; new_id=$(cat /dev/urandom | tr -dc 'a-f0-9' | head -c 16 2>/dev/null)

    if su -c "settings put secure android_id '$new_id' 2>/dev/null" </dev/null; then
        local verify; verify=$(su -c "settings get secure android_id 2>/dev/null" </dev/null)
        if [ "$verify" = "$new_id" ]; then
            echo -e "  ${GREEN}Android ID moi: $new_id${RESET}"
            log_ok "Da doi Android ID: $current_id -> $new_id"
        else
            echo -e "  ${YELLOW}Da dat nhung can reboot de ap dung${RESET}"
        fi
    else
        echo -e "  ${RED}That bai! Can quyen root cao hon.${RESET}"
    fi
}

# ============================================================
#  XEM LOG
# ============================================================
adv_view_logs() {
    local log_dir="$INSTALL_DIR/logs"
    mapfile -t logs < <(ls -t "$log_dir"/*.log 2>/dev/null)

    if [ ${#logs[@]} -eq 0 ]; then
        echo ""
        echo -e "  ${YELLOW}Chua co log nao.${RESET}"
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

    echo -ne "  Chon log (1-${#logs[@]}) hoac Enter huy: "
    read -r choice </dev/tty
    [ -z "$choice" ] && return

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#logs[@]}" ]; then
        local file="${logs[$((choice-1))]}"
        echo -e "${DIM}  -- 100 dong cuoi: $(basename "$file") --${RESET}"
        tail -100 "$file" | more
    else
        echo -e "  ${RED}So khong hop le!${RESET}"
    fi
    press_enter
}

adv_clear_logs() {
    if confirm "Xoa tat ca log files?"; then
        rm -f "$LOG_DIR"/*.log
        echo -e "  ${GREEN}Da xoa tat ca log files${RESET}"
    fi
    sleep 1
}

# ============================================================
#  THÔNG TIN PACKAGES ĐÃ CÀI
# ============================================================
adv_show_packages_info() {
    echo ""
    echo -e "  ${CYAN}Thong tin packages Roblox:${RESET}"
    line
    printf "  %-18s %-30s %-12s %s\n" "Ten" "Package" "Phien ban" "Trang thai"
    line

    while IFS='|' read -r pkg name; do
        local version
        version=$(su -c "pm dump '$pkg' 2>/dev/null | grep 'versionName=' | head -1 | cut -d= -f2" </dev/null 2>/dev/null)
        local status_str
        if [ -n "$version" ] && [ "$version" != "null" ]; then
            status_str="${GREEN}Da cai${RESET}"
        else
            status_str="${RED}Chua cai${RESET}"
            version="N/A"
        fi
        printf "  %-18s %-30s %-12s " "$name" "$pkg" "v${version}"
        echo -e "$status_str"
    done < <(jq -r '.packages[] | "\(.pkg)|\(.name)"' "$CONFIG_FILE" 2>/dev/null)
    line
    press_enter
}

# ============================================================
#  TÌM PACKAGE NAME CỦA APP ĐANG CHẠY
# ============================================================
adv_find_package() {
    echo ""
    echo -e "  ${CYAN}Tim package name cua app dang foreground...${RESET}"
    echo "  Mo app Roblox/executor truoc, sau do nhan Enter."
    press_enter

    local pkg
    pkg=$(su -c "dumpsys activity activities 2>/dev/null | grep mCurrentFocus | grep -oE '[a-zA-Z0-9.]+/[a-zA-Z0-9._]+' | head -1 | cut -d/ -f1" </dev/null 2>/dev/null)

    if [ -n "$pkg" ]; then
        echo -e "\n  ${GREEN}Package tim duoc: ${BOLD}$pkg${RESET}"
        if confirm "Them package nay vao danh sach?"; then
            echo -ne "  Nhap ten hien thi: "
            read -r name </dev/tty
            local tmp; tmp=$(mktemp)
            jq ".packages += [{\"name\":\"${name:-Unknown}\",\"pkg\":\"$pkg\",\"enabled\":true}]" \
                "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
            echo -e "  ${GREEN}Da them!${RESET}"
        fi
    else
        echo -e "  ${RED}Khong tim duoc package. Dam bao app dang foreground!${RESET}"
    fi
    press_enter
}

# ============================================================
#  CẤU HÌNH AUTO BOOT
# ============================================================
adv_setup_autoboot() {
    local bashrc="$HOME/.bashrc"
    local boot_line="# RblxAutoRejoin autoboot"

    if grep -q "$boot_line" "$bashrc" 2>/dev/null; then
        echo -e "  ${YELLOW}Auto boot dang BAT.${RESET}"
        if confirm "Tat auto boot?"; then
            sed -i "/$boot_line/,+2d" "$bashrc"
            set_config ".advanced.auto_boot" "false"
            echo -e "  ${GREEN}Da tat auto boot.${RESET}"
        fi
    else
        echo -e "  Auto boot CHUA bat."
        echo "  Khi bat, tool se tu chay moi khi mo Termux."
        if confirm "Bat auto boot?"; then
            cat >> "$bashrc" << EOFBOOT

$boot_line
if [ -f "$INSTALL_DIR/main.sh" ]; then
    bash "$INSTALL_DIR/main.sh" start &>/dev/null &
fi
EOFBOOT
            set_config ".advanced.auto_boot" "true"
            echo -e "  ${GREEN}Auto boot da bat!${RESET}"
        fi
    fi
    press_enter
}

# ============================================================
#  MENU ADVANCED
# ============================================================
menu_advanced() {
    while true; do
        clear
        print_header
        echo ""
        echo -e "  ${BOLD}ADVANCED SETTINGS${RESET}"
        echo ""
        echo "  1. Xoa cache tat ca Roblox"
        echo "  2. Kill tat ca Roblox"
        echo "  3. Doi Android ID"
        echo "  4. Xem log files"
        echo "  5. Xoa tat ca log"
        echo "  6. Thong tin packages da cai"
        echo "  7. Tim package name app dang chay"
        echo "  8. Cai Auto Boot"
        echo "  9. Quay lai"
        line
        echo -ne "${CYAN}  Chon: ${RESET}"
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
            *) echo -e "${RED}  Lua chon khong hop le!${RESET}"; sleep 0.8 ;;
        esac
    done
}
