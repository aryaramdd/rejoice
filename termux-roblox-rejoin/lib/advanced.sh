#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ADVANCED.SH - Tính năng nâng cao
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh" 2>/dev/null

# ============================================================
#  XOÁ CACHE TẤT CẢ PACKAGE
# ============================================================
adv_clear_all_cache() {
    echo -e "\n${YELLOW}  Đang xoá cache các Roblox packages...${RESET}"
    line

    while IFS='|' read -r pkg name; do
        echo -ne "  ${CYAN}$name${RESET} ($pkg)..."
        # Chỉ xoá thư mục cache, không xoá data
        local cleared=false
        for cache_dir in \
            "/data/data/$pkg/cache" \
            "/data/data/$pkg/code_cache" \
            "/sdcard/Android/data/$pkg/cache"
        do
            if su -c "[ -d '$cache_dir' ]" 2>/dev/null; then
                su -c "rm -rf '$cache_dir'/* 2>/dev/null"
                cleared=true
            fi
        done

        if $cleared; then
            echo -e " ${GREEN}✓ Done${RESET}"
        else
            echo -e " ${DIM}(không có cache hoặc chưa cài)${RESET}"
        fi
    done < <(jq -r '.packages[] | "\(.pkg)|\(.name)"' "$CONFIG_FILE" 2>/dev/null)
}

# ============================================================
#  KILL TẤT CẢ ROBLOX PACKAGES
# ============================================================
adv_kill_all() {
    echo -e "\n${YELLOW}  Kill tất cả Roblox packages...${RESET}"
    line

    while IFS='|' read -r pkg name; do
        echo -ne "  ${CYAN}$name${RESET}..."
        su -c "am force-stop '$pkg' 2>/dev/null"
        local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')
        [ -n "$pid" ] && su -c "kill -9 $pid 2>/dev/null"
        echo -e " ${RED}killed${RESET}"
    done < <(jq -r '.packages[] | "\(.pkg)|\(.name)"' "$CONFIG_FILE" 2>/dev/null)
}

# ============================================================
#  ĐỔI ANDROID ID
# ============================================================
adv_change_android_id() {
    echo -e "\n${YELLOW}  ⚠  CẢNH BÁO: Đổi Android ID${RESET}"
    echo "  Android ID là định danh duy nhất của thiết bị."
    echo "  Đổi nó có thể ảnh hưởng đến: Google Play, apps khác, license..."
    echo "  Chỉ dùng nếu bạn biết mình đang làm gì!"
    line

    if ! confirm "Bạn có chắc muốn đổi Android ID?"; then
        echo -e "  ${DIM}Đã huỷ.${RESET}"
        return
    fi

    # Lấy ID hiện tại
    local current_id=$(su -c "settings get secure android_id 2>/dev/null")
    echo -e "  ID hiện tại: ${DIM}$current_id${RESET}"

    # Tạo ID mới (hex 16 ký tự)
    local new_id=$(cat /dev/urandom | tr -dc 'a-f0-9' | head -c 16 2>/dev/null)

    # Thử các cách set android_id
    if su -c "settings put secure android_id '$new_id' 2>/dev/null"; then
        local verify=$(su -c "settings get secure android_id 2>/dev/null")
        if [ "$verify" = "$new_id" ]; then
            echo -e "  ${GREEN}✓ Android ID mới: $new_id${RESET}"
            log_ok "Đã đổi Android ID: $current_id → $new_id"
        else
            echo -e "  ${YELLOW}Settings đã đặt nhưng verify không khớp (cần reboot)${RESET}"
        fi
    else
        echo -e "  ${RED}Thất bại! Cần quyền root cao hơn hoặc thử lại.${RESET}"
    fi
}

# ============================================================
#  XEM LOG
# ============================================================
adv_view_logs() {
    local log_dir="$INSTALL_DIR/logs"
    mapfile -t logs < <(ls -t "$log_dir"/*.log 2>/dev/null)

    if [ ${#logs[@]} -eq 0 ]; then
        echo -e "\n  ${YELLOW}Chưa có log nào.${RESET}"
        press_enter; return
    fi

    echo -e "\n${CYAN}  Log files:${RESET}"
    line
    for i in "${!logs[@]}"; do
        local size; size=$(du -sh "${logs[$i]}" 2>/dev/null | cut -f1)
        printf "  %2d. %-40s %s\n" "$((i+1))" "$(basename "${logs[$i]}")" "${size:-?}"
    done
    line

    echo -ne "  Chọn log (1-${#logs[@]}) hoặc Enter để hủy: "
    read -r choice
    [ -z "$choice" ] && return

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#logs[@]}" ]; then
        local file="${logs[$((choice-1))]}"
        echo -e "${DIM}  ── Hiển thị 100 dòng cuối của: $(basename "$file") ──${RESET}"
        tail -100 "$file" | more
    else
        echo -e "  ${RED}Số không hợp lệ!${RESET}"
    fi
    press_enter
}

adv_clear_logs() {
    if confirm "Xoá tất cả log files?"; then
        rm -f "$LOG_DIR"/*.log
        echo -e "  ${GREEN}✓ Đã xoá tất cả log files${RESET}"
    fi
    sleep 1
}

# ============================================================
#  THÔNG TIN PACKAGES ĐÃ CÀI
# ============================================================
adv_show_packages_info() {
    echo -e "\n${CYAN}  Thông tin packages Roblox:${RESET}"
    line
    printf "  %-20s %-30s %-15s %s\n" "Tên" "Package" "Phiên bản" "Trạng thái"
    line

    while IFS='|' read -r pkg name; do
        local version
        version=$(su -c "pm dump '$pkg' 2>/dev/null | grep 'versionName=' | head -1 | cut -d= -f2" 2>/dev/null)
        local status
        if [ -n "$version" ]; then
            status="${GREEN}✓ Đã cài${RESET}"
        else
            status="${RED}✗ Chưa cài${RESET}"
            version="N/A"
        fi
        printf "  %-20s %-30s %-15s " "$name" "$pkg" "v${version}"
        echo -e "$status"
    done < <(jq -r '.packages[] | "\(.pkg)|\(.name)"' "$CONFIG_FILE" 2>/dev/null)
    line
    press_enter
}

# ============================================================
#  TÌM PACKAGE NAME CỦA APP ĐANG CHẠY
# ============================================================
adv_find_package() {
    echo -e "\n${CYAN}  Tìm package name của app đang foreground...${RESET}"
    echo "  Mở app Roblox/executor của bạn lên trước, sau đó nhấn Enter."
    press_enter

    local pkg=$(su -c "dumpsys activity activities 2>/dev/null | grep mCurrentFocus | grep -oE '[a-zA-Z0-9.]+/[a-zA-Z0-9._]+' | head -1 | cut -d/ -f1" 2>/dev/null)

    if [ -n "$pkg" ]; then
        echo -e "\n  ${GREEN}Package tìm được: ${BOLD}$pkg${RESET}"
        if confirm "Thêm package này vào danh sách?"; then
            echo -ne "  Nhập tên hiển thị: "
            read -r name
            local tmp; tmp=$(mktemp)
            jq ".packages += [{\"name\":\"${name:-Unknown}\",\"pkg\":\"$pkg\",\"enabled\":true}]" \
                "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
            echo -e "  ${GREEN}✓ Đã thêm!${RESET}"
        fi
    else
        echo -e "  ${RED}Không tìm được package. Đảm bảo app đang foreground!${RESET}"
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
        echo -e "  ${YELLOW}Auto boot đang được bật.${RESET}"
        if confirm "Tắt auto boot?"; then
            sed -i "/$boot_line/,+2d" "$bashrc"
            set_config ".advanced.auto_boot" "false"
            echo -e "  ${GREEN}Đã tắt auto boot.${RESET}"
        fi
    else
        echo -e "  Auto boot CHƯA bật."
        echo "  Khi bật, tool sẽ tự chạy mỗi khi mở Termux."
        if confirm "Bật auto boot?"; then
            cat >> "$bashrc" << EOFBOOT

$boot_line
# Tự động chạy Auto Rejoin khi mở Termux
if [ -f "$INSTALL_DIR/main.sh" ]; then
    bash "$INSTALL_DIR/main.sh" start &>/dev/null &
fi
EOFBOOT
            set_config ".advanced.auto_boot" "true"
            echo -e "  ${GREEN}✓ Auto boot đã bật!${RESET}"
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
        echo -e "\n${BOLD}  ⚙  ADVANCED SETTINGS${RESET}\n"
        echo "  1. 🗑  Xoá cache tất cả Roblox"
        echo "  2. 💀 Kill tất cả Roblox"
        echo "  3. 🔀 Đổi Android ID"
        echo "  4. 📋 Xem log files"
        echo "  5. 🗑  Xoá tất cả log"
        echo "  6. 📦 Thông tin packages đã cài"
        echo "  7. 🔍 Tìm package name app đang chạy"
        echo "  8. 🔁 Cài Auto Boot"
        echo "  9. ↩  Quay lại"
        line
        echo -ne "${CYAN}  Chọn: ${RESET}"
        read -r choice

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
            *) echo -e "${RED}  Lựa chọn không hợp lệ!${RESET}"; sleep 0.8 ;;
        esac
    done
}
