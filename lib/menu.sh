#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  MENU.SH - Giao diện menu quản lý
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh" 2>/dev/null

# ============================================================
#  MENU QUẢN LÝ PACKAGE
# ============================================================
menu_packages() {
    while true; do
        clear
        print_header
        echo -e "\n${BOLD}  📦 QUẢN LÝ PACKAGE ROBLOX${RESET}\n"

        local active; active=$(get_config ".active_package")
        local i=1

        # Danh sách package
        echo -e "  ${DIM}No.  Status    Tên                     Package${RESET}"
        line
        while IFS='|' read -r pkg name enabled; do
            local mark status_color
            if [ "$pkg" = "$active" ]; then
                mark="${YELLOW}★ ACTIVE ${RESET}"
            elif [ "$enabled" = "true" ]; then
                mark="${GREEN}● Enabled${RESET}"
            else
                mark="${RED}○ Off    ${RESET}"
            fi

            # Kiểm tra app có cài không
            local installed=""
            su -c "pm path '$pkg' &>/dev/null" 2>/dev/null && installed="${GREEN}✓${RESET}" || installed="${DIM}?${RESET}"

            printf "  %2d.  %b %-22s %s %b\n" "$i" "$mark" "$name" "$pkg" "$installed"
            i=$((i+1))
        done < <(jq -r '.packages[] | "\(.pkg)|\(.name)|\(.enabled)"' "$CONFIG_FILE" 2>/dev/null)
        line
        echo -e "  ${YELLOW}★${RESET}=Active  ${GREEN}●${RESET}=On  ${RED}○${RESET}=Off  ${GREEN}✓${RESET}=Đã cài"
        echo ""
        echo -e "  ${BOLD}[A]${RESET} Thêm package mới"
        echo -e "  ${BOLD}[S]${RESET} Chọn package active (theo số)"
        echo -e "  ${BOLD}[T]${RESET} Toggle on/off (theo số)"
        echo -e "  ${BOLD}[D]${RESET} Xoá package (theo số)"
        echo -e "  ${BOLD}[B]${RESET} Quay lại"
        line
        echo -ne "${CYAN}  Chọn: ${RESET}"
        read -r choice

        case ${choice,,} in
            a)
                echo -e "\n  ${CYAN}Thêm Package Mới${RESET}"
                echo -ne "  Tên hiển thị (vd: Delta Executor): "
                read -r name
                [ -z "$name" ] && { echo -e "  ${RED}Tên không được rỗng!${RESET}"; sleep 1; continue; }
                echo -ne "  Package name (vd: com.vng.njnj): "
                read -r pkg
                [ -z "$pkg" ] && { echo -e "  ${RED}Package name không được rỗng!${RESET}"; sleep 1; continue; }

                local tmp; tmp=$(mktemp)
                jq ".packages += [{\"name\":\"$name\",\"pkg\":\"$pkg\",\"enabled\":true}]" \
                    "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
                echo -e "  ${GREEN}✓ Đã thêm: $name ($pkg)${RESET}"
                sleep 1
                ;;
            s)
                local total; total=$(jq '.packages | length' "$CONFIG_FILE")
                echo -ne "  Nhập số thứ tự (1-$total): "
                read -r num
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$total" ]; then
                    local new_pkg; new_pkg=$(jq -r ".packages[$((num-1))].pkg" "$CONFIG_FILE")
                    set_config ".active_package" "\"$new_pkg\""
                    echo -e "  ${GREEN}✓ Active package: $new_pkg${RESET}"
                else
                    echo -e "  ${RED}Số không hợp lệ!${RESET}"
                fi
                sleep 1
                ;;
            t)
                local total; total=$(jq '.packages | length' "$CONFIG_FILE")
                echo -ne "  Số thứ tự cần toggle (1-$total): "
                read -r num
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$total" ]; then
                    local cur; cur=$(jq -r ".packages[$((num-1))].enabled" "$CONFIG_FILE")
                    local new_val="true"
                    [ "$cur" = "true" ] && new_val="false"
                    local tmp; tmp=$(mktemp)
                    jq ".packages[$((num-1))].enabled = $new_val" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
                    echo -e "  ${GREEN}✓ Đã set enabled=$new_val${RESET}"
                else
                    echo -e "  ${RED}Số không hợp lệ!${RESET}"
                fi
                sleep 1
                ;;
            d)
                local total; total=$(jq '.packages | length' "$CONFIG_FILE")
                echo -ne "  Số thứ tự cần xoá (1-$total): "
                read -r num
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$total" ]; then
                    local del_name; del_name=$(jq -r ".packages[$((num-1))].name" "$CONFIG_FILE")
                    if confirm "Xoá '$del_name'?"; then
                        local tmp; tmp=$(mktemp)
                        jq "del(.packages[$((num-1))])" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
                        echo -e "  ${GREEN}✓ Đã xoá!${RESET}"
                    fi
                else
                    echo -e "  ${RED}Số không hợp lệ!${RESET}"
                fi
                sleep 1
                ;;
            b) break ;;
            *) echo -e "  ${RED}Lựa chọn không hợp lệ!${RESET}"; sleep 0.8 ;;
        esac
    done
}

# ============================================================
#  MENU CONFIG GAME
# ============================================================
menu_game_config() {
    while true; do
        clear
        print_header
        echo -e "\n${BOLD}  🎮 CẤU HÌNH GAME${RESET}\n"

        local place_id; place_id=$(get_config ".game.place_id // \"chưa đặt\"")
        local is_private; is_private=$(get_config ".game.is_private")
        local access_code; access_code=$(get_config ".game.access_code // \"\"")
        local full_link; full_link=$(get_config ".game.full_link // \"chưa đặt\"")

        echo -e "  ${DIM}Cấu hình hiện tại:${RESET}"
        echo -e "  Place ID:  ${CYAN}${place_id}${RESET}"
        echo -e "  Private:   ${CYAN}${is_private}${RESET}"
        if [ -n "$access_code" ] && [ "$access_code" != "null" ] && [ "$access_code" != "" ]; then
            echo -e "  VIP Code:  ${CYAN}${access_code:0:20}...${RESET}"
        fi
        [ "$full_link" != "chưa đặt" ] && echo -e "  Full Link: ${DIM}${full_link:0:50}...${RESET}"
        line

        echo "  1. Nhập Place ID (public game)"
        echo "  2. Nhập VIP/Private Server Link (toàn bộ URL)"
        echo "  3. Nhập Place ID + Access Code riêng"
        echo "  4. Xoá cấu hình game"
        echo "  5. Quay lại"
        line
        echo -ne "${CYAN}  Chọn: ${RESET}"
        read -r choice

        case $choice in
            1)
                echo -e "\n  ${DIM}Lấy từ URL: roblox.com/games/XXXXXXXXX${RESET}"
                echo -ne "  Nhập Place ID: "
                read -r pid
                if [[ "$pid" =~ ^[0-9]+$ ]]; then
                    set_config ".game.place_id" "\"$pid\""
                    set_config ".game.is_private" "false"
                    set_config ".game.access_code" "null"
                    set_config ".game.full_link" "null"
                    echo -e "  ${GREEN}✓ Đã lưu Place ID: $pid${RESET}"
                else
                    echo -e "  ${RED}Place ID phải là số!${RESET}"
                fi
                sleep 1
                ;;
            2)
                echo -e "\n  ${DIM}Ví dụ: https://www.roblox.com/games/12345678?privateServerLinkCode=XXXXX${RESET}"
                echo -ne "  Paste VIP link: "
                read -r link
                if [ -n "$link" ]; then
                    local pid=$(echo "$link" | grep -oE '/games/[0-9]+' | grep -oE '[0-9]+' | head -1)
                    local code=$(echo "$link" | grep -oE 'privateServerLinkCode=[^&]+' | cut -d= -f2)

                    if [ -z "$pid" ]; then
                        echo -e "  ${RED}Không tìm được Place ID trong link!${RESET}"
                    else
                        set_config ".game.full_link" "\"$link\""
                        set_config ".game.place_id" "\"$pid\""
                        set_config ".game.access_code" "\"${code:-}\""
                        set_config ".game.is_private" "true"
                        echo -e "  ${GREEN}✓ VIP Server | Place: $pid${RESET}"
                        [ -n "$code" ] && echo -e "  ${GREEN}  Code: ${code:0:20}...${RESET}"
                    fi
                fi
                sleep 1
                ;;
            3)
                echo -ne "  Place ID: "
                read -r pid
                echo -ne "  Access Code: "
                read -r code
                if [[ "$pid" =~ ^[0-9]+$ ]]; then
                    set_config ".game.place_id" "\"$pid\""
                    set_config ".game.access_code" "\"$code\""
                    set_config ".game.is_private" "true"
                    set_config ".game.full_link" "null"
                    echo -e "  ${GREEN}✓ Đã lưu!${RESET}"
                else
                    echo -e "  ${RED}Place ID không hợp lệ!${RESET}"
                fi
                sleep 1
                ;;
            4)
                if confirm "Xoá cấu hình game?"; then
                    set_config ".game.place_id" "null"
                    set_config ".game.access_code" "null"
                    set_config ".game.full_link" "null"
                    set_config ".game.is_private" "false"
                    echo -e "  ${GREEN}✓ Đã xoá!${RESET}"
                fi
                sleep 1
                ;;
            5) break ;;
            *) echo -e "  ${RED}Lựa chọn không hợp lệ!${RESET}"; sleep 0.8 ;;
        esac
    done
}

# ============================================================
#  MENU WEBHOOK
# ============================================================
menu_webhook() {
    while true; do
        clear
        print_header
        echo -e "\n${BOLD}  🔔 DISCORD WEBHOOK${RESET}\n"

        local url; url=$(get_config ".webhook.url // \"chưa đặt\"")
        local enabled; enabled=$(get_config ".webhook.enabled")
        local n_rejoin; n_rejoin=$(get_config ".webhook.notify_rejoin")
        local n_crash; n_crash=$(get_config ".webhook.notify_crash")
        local n_success; n_success=$(get_config ".webhook.notify_success")
        local username; username=$(get_config ".webhook.username")

        echo -e "  Webhook URL: ${DIM}${url:0:50}${RESET}"
        echo -ne "  Trạng thái: "
        [ "$enabled" = "true" ] && echo -e "${GREEN}● BẬT${RESET}" || echo -e "${RED}● TẮT${RESET}"
        echo -e "  Bot name:   ${CYAN}$username${RESET}"
        line
        echo -ne "  1. Đặt Webhook URL"
        echo ""
        echo -ne "  2. Bật/Tắt webhook  → "
        [ "$enabled" = "true" ] && echo -e "${GREEN}BẬT${RESET}" || echo -e "${RED}TẮT${RESET}"
        echo -ne "  3. Notify Rejoin    → "
        [ "$n_rejoin" = "true" ] && echo -e "${GREEN}BẬT${RESET}" || echo -e "${RED}TẮT${RESET}"
        echo -ne "  4. Notify Crash     → "
        [ "$n_crash" = "true" ] && echo -e "${GREEN}BẬT${RESET}" || echo -e "${RED}TẮT${RESET}"
        echo -ne "  5. Notify Success   → "
        [ "$n_success" = "true" ] && echo -e "${GREEN}BẬT${RESET}" || echo -e "${RED}TẮT${RESET}"
        echo "  6. Đổi tên bot"
        echo "  7. Gửi test message"
        echo "  8. Quay lại"
        line
        echo -ne "${CYAN}  Chọn: ${RESET}"
        read -r choice

        case $choice in
            1)
                echo -e "\n  ${DIM}Cách lấy: Discord Server → Settings → Integrations → Webhooks${RESET}"
                echo -ne "  Paste Webhook URL: "
                read -r wurl
                if [[ "$wurl" == *"discord.com/api/webhooks/"* ]]; then
                    set_config ".webhook.url" "\"$wurl\""
                    set_config ".webhook.enabled" "true"
                    echo -e "  ${GREEN}✓ Đã lưu và bật webhook!${RESET}"
                else
                    echo -e "  ${RED}URL không hợp lệ! Phải bắt đầu bằng https://discord.com/api/webhooks/${RESET}"
                fi
                sleep 1
                ;;
            2)
                local cur; cur=$(get_config ".webhook.enabled")
                [ "$cur" = "true" ] && set_config ".webhook.enabled" "false" || set_config ".webhook.enabled" "true"
                ;;
            3)
                local cur; cur=$(get_config ".webhook.notify_rejoin")
                [ "$cur" = "true" ] && set_config ".webhook.notify_rejoin" "false" || set_config ".webhook.notify_rejoin" "true"
                ;;
            4)
                local cur; cur=$(get_config ".webhook.notify_crash")
                [ "$cur" = "true" ] && set_config ".webhook.notify_crash" "false" || set_config ".webhook.notify_crash" "true"
                ;;
            5)
                local cur; cur=$(get_config ".webhook.notify_success")
                [ "$cur" = "true" ] && set_config ".webhook.notify_success" "false" || set_config ".webhook.notify_success" "true"
                ;;
            6)
                echo -ne "  Tên bot mới: "
                read -r bname
                [ -n "$bname" ] && set_config ".webhook.username" "\"$bname\""
                ;;
            7)
                source "$HOME/roblox-rejoin/lib/webhook.sh" 2>/dev/null
                echo -ne "  Đang gửi test..."
                send_webhook_test
                sleep 2
                echo -e "\r  ${GREEN}✓ Đã gửi! Kiểm tra Discord của bạn.${RESET}"
                sleep 1
                ;;
            8) break ;;
            *) echo -e "  ${RED}Lựa chọn không hợp lệ!${RESET}"; sleep 0.8 ;;
        esac
    done
}

# ============================================================
#  STATUS DASHBOARD
# ============================================================
show_status() {
    clear
    print_header
    echo -e "\n${BOLD}  📊 STATUS DASHBOARD${RESET}\n"

    local pkg; pkg=$(get_config ".active_package // \"N/A\"")
    local place_id; place_id=$(get_config ".game.place_id // \"chưa đặt\"")
    local is_private; is_private=$(get_config ".game.is_private")
    local check_int; check_int=$(get_config ".timing.check_interval")
    local rejoin_del; rejoin_del=$(get_config ".timing.rejoin_delay")
    local total_r; total_r=$(get_config ".stats.total_rejoins // 0")
    local total_c; total_c=$(get_config ".stats.total_crashes // 0")
    local last_r; last_r=$(get_config ".stats.last_rejoin // \"belum ada\"")
    local ram; ram=$(get_ram_info)
    local uptime; uptime=$(get_uptime)
    local webhook_en; webhook_en=$(get_config ".webhook.enabled")

    # App status
    local app_pid; app_pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')
    local app_status
    if [ -n "$app_pid" ]; then
        app_status="${GREEN}● Đang chạy (PID: $app_pid)${RESET}"
    else
        app_status="${RED}● Không chạy${RESET}"
    fi

    echo -e "  ${CYAN}┌─ GAME CONFIG ─────────────────────────────┐${RESET}"
    echo -e "  ${CYAN}│${RESET}  Package:    ${BOLD}$pkg${RESET}"
    echo -e "  ${CYAN}│${RESET}  Place ID:   $place_id"
    echo -e "  ${CYAN}│${RESET}  Private:    $is_private"
    echo -e "  ${CYAN}│${RESET}  App:        $app_status"
    echo -e "  ${CYAN}└───────────────────────────────────────────┘${RESET}"

    echo -e "  ${CYAN}┌─ TIMING ──────────────────────────────────┐${RESET}"
    echo -e "  ${CYAN}│${RESET}  Check interval:  ${check_int}s"
    echo -e "  ${CYAN}│${RESET}  Rejoin delay:    ${rejoin_del}s"
    echo -e "  ${CYAN}└───────────────────────────────────────────┘${RESET}"

    echo -e "  ${CYAN}┌─ STATS ───────────────────────────────────┐${RESET}"
    echo -e "  ${CYAN}│${RESET}  ${GREEN}Tổng rejoins:${RESET}   $total_r"
    echo -e "  ${CYAN}│${RESET}  ${RED}Tổng crashes:${RESET}   $total_c"
    echo -e "  ${CYAN}│${RESET}  Rejoin cuối:    $last_r"
    echo -e "  ${CYAN}│${RESET}  Tool uptime:    $uptime"
    echo -e "  ${CYAN}└───────────────────────────────────────────┘${RESET}"

    echo -e "  ${CYAN}┌─ SYSTEM ──────────────────────────────────┐${RESET}"
    echo -e "  ${CYAN}│${RESET}  RAM:     $ram"
    echo -ne "  ${CYAN}│${RESET}  Webhook: "
    [ "$webhook_en" = "true" ] && echo -e "${GREEN}BẬT${RESET}" || echo -e "${RED}TẮT${RESET}"
    echo -e "  ${CYAN}└───────────────────────────────────────────┘${RESET}"

    echo ""
    press_enter
}
