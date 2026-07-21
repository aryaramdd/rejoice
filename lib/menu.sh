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
        echo ""
        echo -e "  ${BOLD}QUAN LY PACKAGE ROBLOX${RESET}"
        echo ""

        local active; active=$(get_config ".active_package")
        local i=1

        echo -e "  ${DIM}No.  Trang thai   Ten                  Package${RESET}"
        line
        while IFS='|' read -r pkg name enabled; do
            local mark
            if [ "$pkg" = "$active" ]; then
                mark="${YELLOW}[ACTIVE]  ${RESET}"
            elif [ "$enabled" = "true" ]; then
                mark="${GREEN}[ON]      ${RESET}"
            else
                mark="${RED}[OFF]     ${RESET}"
            fi

            # Kiểm tra app có cài không (dùng </dev/null tránh nuốt stdin)
            local inst_mark
            su -c "pm path '$pkg' &>/dev/null" </dev/null 2>/dev/null \
                && inst_mark="${GREEN}(da cai)${RESET}" \
                || inst_mark="${DIM}(?)${RESET}"

            echo -e "  ${i}.  ${mark}$(printf '%-20s' "$name")  $pkg  $inst_mark"
            i=$(( i + 1 ))
        done < <(jq -r '.packages[] | "\(.pkg)|\(.name)|\(.enabled)"' "$CONFIG_FILE" 2>/dev/null)

        line
        echo "  A. Them package moi"
        echo "  S. Chon package active (nhap so)"
        echo "  T. Bat/Tat package (nhap so)"
        echo "  D. Xoa package (nhap so)"
        echo "  B. Quay lai"
        line
        echo -ne "${CYAN}  Chon: ${RESET}"
        read -r choice </dev/tty

        case ${choice,,} in
            a)
                echo ""
                echo -ne "  Ten hien thi (vd: Delta Executor): "
                read -r name </dev/tty
                [ -z "$name" ] && { echo -e "  ${RED}Ten khong duoc rong!${RESET}"; sleep 1; continue; }
                echo -ne "  Package name (vd: com.vng.njnj): "
                read -r pkg </dev/tty
                [ -z "$pkg" ] && { echo -e "  ${RED}Package name khong duoc rong!${RESET}"; sleep 1; continue; }

                local tmp; tmp=$(mktemp)
                jq ".packages += [{\"name\":\"$name\",\"pkg\":\"$pkg\",\"enabled\":true}]" \
                    "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
                echo -e "  ${GREEN}Da them: $name ($pkg)${RESET}"
                sleep 1
                ;;
            s)
                local total; total=$(jq '.packages | length' "$CONFIG_FILE")
                echo -ne "  Nhap so thu tu (1-$total): "
                read -r num </dev/tty
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$total" ]; then
                    local new_pkg; new_pkg=$(jq -r ".packages[$((num-1))].pkg" "$CONFIG_FILE")
                    set_config ".active_package" "\"$new_pkg\""
                    echo -e "  ${GREEN}Active package: $new_pkg${RESET}"
                else
                    echo -e "  ${RED}So khong hop le!${RESET}"
                fi
                sleep 1
                ;;
            t)
                local total; total=$(jq '.packages | length' "$CONFIG_FILE")
                echo -ne "  So can toggle (1-$total): "
                read -r num </dev/tty
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$total" ]; then
                    local cur; cur=$(jq -r ".packages[$((num-1))].enabled" "$CONFIG_FILE")
                    local new_val="true"
                    [ "$cur" = "true" ] && new_val="false"
                    local tmp; tmp=$(mktemp)
                    jq ".packages[$((num-1))].enabled = $new_val" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
                    echo -e "  ${GREEN}Da set enabled=$new_val${RESET}"
                else
                    echo -e "  ${RED}So khong hop le!${RESET}"
                fi
                sleep 1
                ;;
            d)
                local total; total=$(jq '.packages | length' "$CONFIG_FILE")
                echo -ne "  So can xoa (1-$total): "
                read -r num </dev/tty
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$total" ]; then
                    local del_name; del_name=$(jq -r ".packages[$((num-1))].name" "$CONFIG_FILE")
                    if confirm "Xoa '$del_name'?"; then
                        local tmp; tmp=$(mktemp)
                        jq "del(.packages[$((num-1))])" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
                        echo -e "  ${GREEN}Da xoa!${RESET}"
                    fi
                else
                    echo -e "  ${RED}So khong hop le!${RESET}"
                fi
                sleep 1
                ;;
            b) break ;;
            *) echo -e "  ${RED}Lua chon khong hop le!${RESET}"; sleep 0.8 ;;
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
        echo ""
        echo -e "  ${BOLD}CAU HINH GAME${RESET}"
        echo ""

        local place_id; place_id=$(get_config ".game.place_id")
        local is_private; is_private=$(get_config ".game.is_private")
        local access_code; access_code=$(get_config ".game.access_code")
        local full_link; full_link=$(get_config ".game.full_link")

        echo -e "  Place ID : ${CYAN}${place_id:-chua dat}${RESET}"
        echo -e "  Private  : ${CYAN}${is_private:-false}${RESET}"
        if [ -n "$access_code" ] && [ "$access_code" != "null" ] && [ "$access_code" != "" ]; then
            echo -e "  VIP Code : ${CYAN}${access_code:0:30}...${RESET}"
        fi
        if [ -n "$full_link" ] && [ "$full_link" != "null" ]; then
            echo -e "  Full Link: ${DIM}${full_link:0:50}...${RESET}"
        fi
        line
        echo "  1. Nhap Place ID (public game)"
        echo "  2. Nhap VIP/Private Server Link (toan bo URL)"
        echo "  3. Nhap Place ID + Access Code rieng"
        echo "  4. Xoa cau hinh game"
        echo "  5. Quay lai"
        line
        echo -ne "${CYAN}  Chon: ${RESET}"
        read -r choice </dev/tty

        case $choice in
            1)
                echo ""
                echo -e "  ${DIM}Lay tu URL: roblox.com/games/XXXXXXXXX${RESET}"
                echo -ne "  Nhap Place ID: "
                read -r pid </dev/tty
                if [[ "$pid" =~ ^[0-9]+$ ]]; then
                    set_config ".game.place_id" "\"$pid\""
                    set_config ".game.is_private" "false"
                    set_config ".game.access_code" "null"
                    set_config ".game.full_link" "null"
                    echo -e "  ${GREEN}Da luu Place ID: $pid${RESET}"
                else
                    echo -e "  ${RED}Place ID phai la so!${RESET}"
                fi
                sleep 1
                ;;
            2)
                echo ""
                echo -e "  ${DIM}Vi du: https://www.roblox.com/games/12345678?privateServerLinkCode=XXXXX${RESET}"
                echo -ne "  Paste VIP link: "
                read -r link </dev/tty
                if [ -n "$link" ]; then
                    local pid; pid=$(echo "$link" | grep -oE '/games/[0-9]+' | grep -oE '[0-9]+' | head -1)
                    local code; code=$(echo "$link" | grep -oE 'privateServerLinkCode=[^&]+' | cut -d= -f2)
                    if [ -z "$pid" ]; then
                        echo -e "  ${RED}Khong tim duoc Place ID trong link!${RESET}"
                    else
                        set_config ".game.full_link" "\"$link\""
                        set_config ".game.place_id" "\"$pid\""
                        set_config ".game.access_code" "\"${code:-}\""
                        set_config ".game.is_private" "true"
                        echo -e "  ${GREEN}VIP Server | Place: $pid${RESET}"
                        [ -n "$code" ] && echo -e "  ${GREEN}Code: ${code:0:30}...${RESET}"
                    fi
                fi
                sleep 1
                ;;
            3)
                echo -ne "  Place ID: "
                read -r pid </dev/tty
                echo -ne "  Access Code: "
                read -r code </dev/tty
                if [[ "$pid" =~ ^[0-9]+$ ]]; then
                    set_config ".game.place_id" "\"$pid\""
                    set_config ".game.access_code" "\"$code\""
                    set_config ".game.is_private" "true"
                    set_config ".game.full_link" "null"
                    echo -e "  ${GREEN}Da luu!${RESET}"
                else
                    echo -e "  ${RED}Place ID khong hop le!${RESET}"
                fi
                sleep 1
                ;;
            4)
                if confirm "Xoa cau hinh game?"; then
                    set_config ".game.place_id" "null"
                    set_config ".game.access_code" "null"
                    set_config ".game.full_link" "null"
                    set_config ".game.is_private" "false"
                    echo -e "  ${GREEN}Da xoa!${RESET}"
                fi
                sleep 1
                ;;
            5) break ;;
            *) echo -e "  ${RED}Lua chon khong hop le!${RESET}"; sleep 0.8 ;;
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
        echo ""
        echo -e "  ${BOLD}DISCORD WEBHOOK${RESET}"
        echo ""

        local url; url=$(get_config ".webhook.url")
        local enabled; enabled=$(get_config ".webhook.enabled")
        local n_rejoin; n_rejoin=$(get_config ".webhook.notify_rejoin")
        local n_crash; n_crash=$(get_config ".webhook.notify_crash")
        local n_success; n_success=$(get_config ".webhook.notify_success")
        local username; username=$(get_config ".webhook.username")

        # Trạng thái BẬT/TẮT
        local en_str; [ "$enabled"   = "true" ] && en_str="${GREEN}BAT${RESET}"  || en_str="${RED}TAT${RESET}"
        local rj_str; [ "$n_rejoin"  = "true" ] && rj_str="${GREEN}BAT${RESET}"  || rj_str="${RED}TAT${RESET}"
        local cr_str; [ "$n_crash"   = "true" ] && cr_str="${GREEN}BAT${RESET}"  || cr_str="${RED}TAT${RESET}"
        local su_str; [ "$n_success" = "true" ] && su_str="${GREEN}BAT${RESET}"  || su_str="${RED}TAT${RESET}"

        echo -e "  URL     : ${DIM}${url:0:45}${RESET}"
        echo -e "  Bot name: ${CYAN}${username:-RobloxBot}${RESET}"
        line
        echo -e "  1. Dat Webhook URL"
        echo -e "  2. Bat/Tat webhook       [$en_str]"
        echo -e "  3. Notify khi Rejoin     [$rj_str]"
        echo -e "  4. Notify khi Crash      [$cr_str]"
        echo -e "  5. Notify khi Thanh cong [$su_str]"
        echo -e "  6. Doi ten bot"
        echo -e "  7. Gui test message"
        echo -e "  8. Quay lai"
        line
        echo -ne "${CYAN}  Chon: ${RESET}"
        read -r choice </dev/tty

        case $choice in
            1)
                echo ""
                echo -e "  ${DIM}Lay tu: Discord Server -> Settings -> Integrations -> Webhooks${RESET}"
                echo -ne "  Paste Webhook URL: "
                read -r wurl </dev/tty
                if [[ "$wurl" == *"discord.com/api/webhooks/"* ]]; then
                    set_config ".webhook.url" "\"$wurl\""
                    set_config ".webhook.enabled" "true"
                    echo -e "  ${GREEN}Da luu va bat webhook!${RESET}"
                else
                    echo -e "  ${RED}URL khong hop le! Phai bat dau bang https://discord.com/api/webhooks/${RESET}"
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
                echo -ne "  Ten bot moi: "
                read -r bname </dev/tty
                [ -n "$bname" ] && set_config ".webhook.username" "\"$bname\""
                ;;
            7)
                source "$HOME/roblox-rejoin/lib/webhook.sh" 2>/dev/null
                echo -ne "  Dang gui test..."
                send_webhook_test
                echo -e "\r  ${GREEN}Da gui! Kiem tra Discord cua ban.${RESET}"
                sleep 2
                ;;
            8) break ;;
            *) echo -e "  ${RED}Lua chon khong hop le!${RESET}"; sleep 0.8 ;;
        esac
    done
}

# ============================================================
#  STATUS DASHBOARD
# ============================================================
show_status() {
    clear
    print_header
    echo ""
    echo -e "  ${BOLD}STATUS DASHBOARD${RESET}"
    echo ""

    local pkg; pkg=$(get_config ".active_package")
    local place_id; place_id=$(get_config ".game.place_id")
    local is_private; is_private=$(get_config ".game.is_private")
    local check_int; check_int=$(get_config ".timing.check_interval")
    local rejoin_del; rejoin_del=$(get_config ".timing.rejoin_delay")
    local total_r; total_r=$(get_config ".stats.total_rejoins // 0")
    local total_c; total_c=$(get_config ".stats.total_crashes // 0")
    local last_r; last_r=$(get_config ".stats.last_rejoin")
    local ram; ram=$(get_ram_info)
    local uptime_val; uptime_val=$(get_uptime)
    local webhook_en; webhook_en=$(get_config ".webhook.enabled")

    # App status (dùng </dev/null)
    local app_pid=""
    if [[ "$pkg" =~ ^[a-zA-Z0-9._]+$ ]]; then
        app_pid=$(su -c "pidof '$pkg' 2>/dev/null" </dev/null 2>/dev/null | awk '{print $1}')
    fi

    echo "  --- GAME CONFIG ---"
    echo -e "  Package  : ${CYAN}${pkg:-chua chon}${RESET}"
    echo -e "  Place ID : ${place_id:-chua dat}"
    echo -e "  Private  : ${is_private:-false}"
    echo -ne "  App      : "
    if [ -n "$app_pid" ]; then
        echo -e "${GREEN}CHAY (PID: $app_pid)${RESET}"
    else
        echo -e "${RED}DUNG${RESET}"
    fi
    echo ""
    echo "  --- TIMING ---"
    echo "  Check interval : ${check_int}s"
    echo "  Rejoin delay   : ${rejoin_del}s"
    echo ""
    echo "  --- THONG KE ---"
    echo -e "  Tong rejoins : ${GREEN}$total_r${RESET}"
    echo -e "  Tong crashes : ${RED}$total_c${RESET}"
    echo "  Rejoin cuoi  : ${last_r:-chua co}"
    echo "  Tool uptime  : $uptime_val"
    echo ""
    echo "  --- SYSTEM ---"
    echo "  RAM     : $ram"
    echo -ne "  Webhook : "
    [ "$webhook_en" = "true" ] && echo -e "${GREEN}BAT${RESET}" || echo -e "${RED}TAT${RESET}"

    echo ""
    press_enter
}
