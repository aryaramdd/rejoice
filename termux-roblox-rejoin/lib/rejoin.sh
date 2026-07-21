#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  REJOIN.SH - Thực hiện Rejoin Game
#  Hỗ trợ deep link, VIP server, fallback methods
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh"

# ============================================================
#  KILL APP
# ============================================================
kill_roblox() {
    local pkg=$1
    log_info "Đang kill $pkg..."

    # Phương pháp 1: am force-stop (sạch nhất)
    su -c "am force-stop '$pkg' 2>/dev/null"
    sleep 0.5

    # Phương pháp 2: kill bằng PID
    local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')
    if [ -n "$pid" ]; then
        su -c "kill -SIGTERM $pid 2>/dev/null"
        sleep 0.3
        # Force kill nếu vẫn còn
        kill -0 "$pid" 2>/dev/null && su -c "kill -9 $pid 2>/dev/null"
    fi

    # Verify đã chết
    sleep 0.5
    local still_alive=$(su -c "pidof '$pkg' 2>/dev/null")
    if [ -z "$still_alive" ]; then
        log_ok "Đã kill $pkg thành công"
        return 0
    else
        log_warn "Kill chưa hoàn toàn, thử lần 2..."
        su -c "am kill '$pkg' 2>/dev/null"
        sleep 1
        return 0
    fi
}

# ============================================================
#  XOÁ CACHE ROBLOX
# ============================================================
clear_roblox_cache() {
    local pkg=$1
    log_info "Xoá cache: $pkg"

    # pm clear xoá cả data (cẩn thận với một số executor)
    # Chỉ xoá cache dir thôi để an toàn hơn
    local cache_paths=(
        "/data/data/$pkg/cache"
        "/data/data/$pkg/code_cache"
        "/sdcard/Android/data/$pkg/cache"
        "/sdcard/Android/obb/$pkg"
    )

    for path in "${cache_paths[@]}"; do
        if su -c "[ -d '$path' ]" 2>/dev/null; then
            su -c "rm -rf '$path'/* 2>/dev/null"
            log_ok "Xoá: $path"
        fi
    done
}

# ============================================================
#  BUILD DEEP LINK
# ============================================================
build_deeplink() {
    local place_id=$(get_config ".game.place_id")
    local access_code=$(get_config ".game.access_code")
    local is_private=$(get_config ".game.is_private")
    local full_link=$(get_config ".game.full_link")

    # Nếu có full link → parse từ đó
    if [ -n "$full_link" ] && [ "$full_link" != "null" ] && [ "$full_link" != "" ]; then
        # Parse place_id từ URL: /games/XXXXXXXX hoặc /games/XXXXXXXX/
        place_id=$(echo "$full_link" | grep -oE '/games/[0-9]+' | grep -oE '[0-9]+' | head -1)
        # Parse access code
        access_code=$(echo "$full_link" | grep -oE 'privateServerLinkCode=[^&]+' | cut -d= -f2)
        is_private="true"
    fi

    # Validate place_id
    if [ -z "$place_id" ] || [ "$place_id" = "null" ]; then
        log_err "Chưa cấu hình Place ID!"
        return 1
    fi

    # Build URL scheme
    if [ "$is_private" = "true" ] && [ -n "$access_code" ] && [ "$access_code" != "null" ]; then
        # VIP/Private server link
        echo "roblox://placeId=${place_id}&accessCode=${access_code}"
    else
        # Public game
        echo "roblox://placeId=${place_id}"
    fi
}

# ============================================================
#  REJOIN METHOD 1: Deep Link (ưu tiên cao nhất)
# ============================================================
rejoin_deeplink() {
    local pkg=$1
    local deeplink
    deeplink=$(build_deeplink) || return 1

    log_info "Rejoin deep link: $deeplink"

    # Thử am start với intent URI
    su -c "am start \
        -a 'android.intent.action.VIEW' \
        -d '$deeplink' \
        -p '$pkg' \
        --activity-clear-task \
        --activity-no-history \
        2>/dev/null"
    return $?
}

# ============================================================
#  REJOIN METHOD 2: Mở activity trực tiếp
# ============================================================
rejoin_launch_activity() {
    local pkg=$1
    log_warn "Method 2: Launch main activity..."

    # Tìm main activity của package
    local main_act=$(su -c "pm dump '$pkg' 2>/dev/null" | \
        grep -A2 "android.intent.action.MAIN" | \
        grep -oE "[a-zA-Z0-9._]+Activity[a-zA-Z0-9._]*" | \
        head -1)

    if [ -n "$main_act" ]; then
        log_info "Main activity: $main_act"
        su -c "am start -n '${pkg}/${main_act}' --activity-clear-task 2>/dev/null"
    else
        # Fallback: monkey launcher
        log_warn "Không tìm được activity, dùng monkey..."
        su -c "monkey -p '$pkg' -c android.intent.category.LAUNCHER 1 2>/dev/null"
    fi
}

# ============================================================
#  REJOIN METHOD 3: URI Launcher fallback
# ============================================================
rejoin_uri_fallback() {
    local pkg=$1
    local place_id=$(get_config ".game.place_id")
    [ -z "$place_id" ] || [ "$place_id" = "null" ] && return 1

    log_warn "Method 3: URI fallback..."
    # Thử các URI scheme khác nhau mà Roblox accept
    local uris=(
        "roblox://placeId=$place_id"
        "https://www.roblox.com/games/$place_id"
    )

    for uri in "${uris[@]}"; do
        log_info "Thử: $uri"
        if su -c "am start -a android.intent.action.VIEW -d '$uri' 2>/dev/null"; then
            return 0
        fi
        sleep 1
    done
    return 1
}

# ============================================================
#  VERIFY: Kiểm tra app đã vào game thành công chưa
# ============================================================
verify_ingame() {
    local pkg=$1
    local wait_time=${2:-15}  # Đợi tối đa N giây

    log_info "Đợi app khởi động (tối đa ${wait_time}s)..."

    for ((i=0; i<wait_time; i++)); do
        sleep 1
        local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')
        if [ -n "$pid" ]; then
            # Kiểm tra activity
            local act=$(check_activity "$pkg" 2>/dev/null || echo "unknown")
            if [ "$act" = "foreground" ]; then
                log_ok "App lên foreground! PID: $pid"
                return 0
            fi
        fi
        echo -ne "\r  ${CYAN}Đợi... ${i}s${RESET}  "
    done
    echo ""

    # Lần kiểm tra cuối: chỉ cần PID tồn tại
    local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')
    if [ -n "$pid" ]; then
        log_ok "App chạy (PID: $pid) nhưng chưa chắc foreground"
        return 0
    fi

    return 1
}

# ============================================================
#  MASTER REJOIN FUNCTION
#  Thực hiện full rejoin với retry logic
# ============================================================
do_rejoin() {
    local pkg=$1
    local reason=${2:-"unknown"}
    local max_retries=$(get_config ".timing.max_retries // 10")
    local rejoin_delay=$(get_config ".timing.rejoin_delay // 8")
    local retry_cooldown=$(get_config ".timing.retry_cooldown // 30")

    log ""
    log_warn "════════════════════════════════════"
    log_warn "🔄 REJOIN TRIGGERED"
    log_warn "  Package: $pkg"
    log_warn "  Lý do:   $reason"
    log_warn "  Thời gian: $(date '+%H:%M:%S')"
    log_warn "════════════════════════════════════"

    # Gửi webhook thông báo rejoin
    source "$HOME/roblox-rejoin/lib/webhook.sh" 2>/dev/null
    send_webhook_rejoin "$pkg" "$reason"
    increment_stat "total_rejoins"
    update_stat "last_rejoin" "$(date '+%Y-%m-%d %H:%M:%S')"

    local attempt=0
    while [ $attempt -lt $max_retries ]; do
        attempt=$((attempt + 1))
        log_info "── Lần thử $attempt/$max_retries ──"

        # Bước 1: Kill app hiện tại
        kill_roblox "$pkg"

        # Bước 2: Xoá cache nếu bật
        local auto_clear=$(get_config ".advanced.auto_clear_cache")
        if [ "$auto_clear" = "true" ] && [ $((attempt % 3)) -eq 0 ]; then
            clear_roblox_cache "$pkg"
        fi

        # Bước 3: Đợi hệ thống ổn định
        log_info "Đợi ${rejoin_delay}s..."
        sleep "$rejoin_delay"

        # Bước 4: Thử rejoin theo thứ tự ưu tiên
        local joined=false

        # Method 1: Deep link (ưu tiên nhất)
        if rejoin_deeplink "$pkg"; then
            if verify_ingame "$pkg" 20; then
                joined=true
            fi
        fi

        # Method 2: Launch activity trực tiếp
        if [ "$joined" = false ]; then
            rejoin_launch_activity "$pkg"
            if verify_ingame "$pkg" 15; then
                joined=true
            fi
        fi

        # Method 3: URI fallback
        if [ "$joined" = false ]; then
            rejoin_uri_fallback "$pkg"
            if verify_ingame "$pkg" 15; then
                joined=true
            fi
        fi

        # Kiểm tra kết quả
        if [ "$joined" = true ]; then
            log_ok "✅ REJOIN THÀNH CÔNG! (lần thử $attempt)"
            send_webhook_success "$pkg" "$attempt"
            return 0
        fi

        # Thử thất bại → đợi trước khi thử lại
        log_warn "Lần thử $attempt thất bại!"
        if [ $attempt -lt $max_retries ]; then
            log_info "Đợi ${retry_cooldown}s trước lần thử tiếp..."
            sleep "$retry_cooldown"
        fi
    done

    # Hết số lần thử
    log_err "❌ REJOIN THẤT BẠI sau $max_retries lần thử!"
    send_webhook_crash "$pkg"
    increment_stat "total_crashes"
    return 1
}
