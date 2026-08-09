#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  REJOIN.SH - Execute Game Rejoin
#  Supports deep link, VIP server, fallback methods
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh"

# ============================================================
#  KILL APP
# ============================================================
kill_roblox() {
    local pkg=$1
    log_info "Killing $pkg..."

    # Method 1: am force-stop (cleanest)
    su -c "am force-stop '$pkg' 2>/dev/null"
    sleep 0.5

    # Method 2: kill by PID
    local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')
    if [ -n "$pid" ]; then
        su -c "kill -SIGTERM $pid 2>/dev/null"
        sleep 0.3
        # Force kill if still alive
        kill -0 "$pid" 2>/dev/null && su -c "kill -9 $pid 2>/dev/null"
    fi

    # Verify it's dead
    sleep 0.5
    local still_alive=$(su -c "pidof '$pkg' 2>/dev/null")
    if [ -z "$still_alive" ]; then
        log_ok "Successfully killed $pkg"
        return 0
    else
        log_warn "Kill incomplete, trying again..."
        su -c "am kill '$pkg' 2>/dev/null"
        sleep 1
        return 0
    fi
}

# ============================================================
#  CLEAR ROBLOX CACHE
# ============================================================
clear_roblox_cache() {
    local pkg=$1
    log_info "Clearing cache: $pkg"

    # pm clear wipes all data (be careful with some executors)
    # Only clear cache dir to be safer
    local cache_paths=(
        "/data/data/$pkg/cache"
        "/data/data/$pkg/code_cache"
        "/sdcard/Android/data/$pkg/cache"
        "/sdcard/Android/obb/$pkg"
    )

    for path in "${cache_paths[@]}"; do
        if su -c "[ -d '$path' ]" 2>/dev/null; then
            su -c "rm -rf '$path'/* 2>/dev/null"
            log_ok "Cleared: $path"
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

    # If full link exists -> parse from it
    if [ -n "$full_link" ] && [ "$full_link" != "null" ] && [ "$full_link" != "" ]; then
        # Parse place_id from URL: /games/XXXXXXXX or /games/XXXXXXXX/
        place_id=$(echo "$full_link" | grep -oE '/games/[0-9]+' | grep -oE '[0-9]+' | head -1)
        # Parse access code
        access_code=$(echo "$full_link" | grep -oE 'privateServerLinkCode=[^&]+' | cut -d= -f2)
        is_private="true"
    fi

    # Validate place_id
    if [ -z "$place_id" ] || [ "$place_id" = "null" ]; then
        log_err "Place ID not configured!"
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
#  REJOIN METHOD 1: Deep Link (highest priority)
# ============================================================
rejoin_deeplink() {
    local pkg=$1
    local deeplink
    deeplink=$(build_deeplink) || return 1

    log_info "Rejoin deep link: $deeplink"

    # Try am start with intent URI
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
#  REJOIN METHOD 2: Open activity directly
# ============================================================
rejoin_launch_activity() {
    local pkg=$1
    log_warn "Method 2: Launch main activity..."

    # Find main activity of package
    local main_act=$(su -c "pm dump '$pkg' 2>/dev/null" | \
        grep -A2 "android.intent.action.MAIN" | \
        grep -oE "[a-zA-Z0-9._]+Activity[a-zA-Z0-9._]*" | \
        head -1)

    if [ -n "$main_act" ]; then
        log_info "Main activity: $main_act"
        su -c "am start -n '${pkg}/${main_act}' --activity-clear-task 2>/dev/null"
    else
        # Fallback: monkey launcher
        log_warn "Activity not found, using monkey..."
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
    # Try different URI schemes that Roblox accepts
    local uris=(
        "roblox://placeId=$place_id"
        "https://www.roblox.com/games/$place_id"
    )

    for uri in "${uris[@]}"; do
        log_info "Trying: $uri"
        if su -c "am start -a android.intent.action.VIEW -d '$uri' 2>/dev/null"; then
            return 0
        fi
        sleep 1
    done
    return 1
}

# ============================================================
#  VERIFY: Check if app has successfully entered game
# ============================================================
verify_ingame() {
    local pkg=$1
    local wait_time=${2:-15}  # Wait up to N seconds

    log_info "Waiting for app to start (up to ${wait_time}s)..."

    for ((i=0; i<wait_time; i++)); do
        sleep 1
        local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')
        if [ -n "$pid" ]; then
            # Check activity
            local act=$(check_activity "$pkg" 2>/dev/null || echo "unknown")
            if [ "$act" = "foreground" ]; then
                log_ok "App is in foreground! PID: $pid"
                return 0
            fi
        fi
        echo -ne "\r  ${CYAN}Waiting... ${i}s${RESET}  "
    done
    echo ""

    # Final check: just need PID to exist
    local pid=$(su -c "pidof '$pkg' 2>/dev/null" | awk '{print $1}')
    if [ -n "$pid" ]; then
        log_ok "App running (PID: $pid) but not necessarily foreground"
        return 0
    fi

    return 1
}

# ============================================================
#  MASTER REJOIN FUNCTION
#  Perform full rejoin with retry logic
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
    log_warn "  Reason:  $reason"
    log_warn "  Time: $(date '+%H:%M:%S')"
    log_warn "════════════════════════════════════"

    # Send webhook rejoin notification
    source "$HOME/roblox-rejoin/lib/webhook.sh" 2>/dev/null
    send_webhook_rejoin "$pkg" "$reason"
    increment_stat "total_rejoins"
    update_stat "last_rejoin" "$(date '+%Y-%m-%d %H:%M:%S')"

    local attempt=0
    while [ $attempt -lt $max_retries ]; do
        attempt=$((attempt + 1))
        log_info "── Attempt $attempt/$max_retries ──"

        # Step 1: Kill current app
        kill_roblox "$pkg"

        # Step 2: Clear cache if enabled
        local auto_clear=$(get_config ".advanced.auto_clear_cache")
        if [ "$auto_clear" = "true" ] && [ $((attempt % 3)) -eq 0 ]; then
            clear_roblox_cache "$pkg"
        fi

        # Step 3: Wait for system to stabilize
        log_info "Waiting ${rejoin_delay}s..."
        sleep "$rejoin_delay"

        # Step 4: Try rejoin in priority order
        local joined=false

        # Method 1: Deep link (highest priority)
        if rejoin_deeplink "$pkg"; then
            if verify_ingame "$pkg" 20; then
                joined=true
            fi
        fi

        # Method 2: Launch activity directly
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

        # Check result
        if [ "$joined" = true ]; then
            log_ok "✅ REJOIN SUCCESSFUL! (attempt $attempt)"
            send_webhook_success "$pkg" "$attempt"
            return 0
        fi

        # Attempt failed -> wait before retrying
        log_warn "Attempt $attempt failed!"
        if [ $attempt -lt $max_retries ]; then
            log_info "Waiting ${retry_cooldown}s before next attempt..."
            sleep "$retry_cooldown"
        fi
    done

    # Out of retries
    log_err "❌ REJOIN FAILED after $max_retries attempts!"
    send_webhook_crash "$pkg"
    increment_stat "total_crashes"
    return 1
}
