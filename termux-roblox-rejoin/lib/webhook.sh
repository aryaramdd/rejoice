#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  WEBHOOK.SH - Gửi thông báo Discord Webhook
# ============================================================

source "$HOME/roblox-rejoin/lib/utils.sh" 2>/dev/null

# ============================================================
#  HÀM GỬI EMBED DISCORD
# ============================================================
send_discord_embed() {
    local title=$1
    local description=$2
    local color=${3:-"3447003"}     # Xanh dương mặc định
    local fields_json=${4:-"[]"}    # Array fields tùy chọn

    # Lấy config
    local webhook_url; webhook_url=$(get_config ".webhook.url")
    local enabled;     enabled=$(get_config ".webhook.enabled")
    local username;    username=$(get_config ".webhook.username // \"Roblox AutoRejoin\"")
    local avatar;      avatar=$(get_config ".webhook.avatar_url // \"\"")

    # Kiểm tra điều kiện
    [ "$enabled" != "true" ] && return 0
    [ -z "$webhook_url" ] || [ "$webhook_url" = "null" ] && return 0
    ! check_internet 2>/dev/null && return 0

    # Build payload JSON
    local payload
    payload=$(jq -n \
        --arg username "$username" \
        --arg avatar "$avatar" \
        --arg title "$title" \
        --arg desc "$description" \
        --argjson color "$color" \
        --argjson fields "$fields_json" \
        '{
            username: $username,
            avatar_url: $avatar,
            embeds: [{
                title: $title,
                description: $desc,
                color: $color,
                fields: $fields,
                footer: {
                    text: "Roblox AutoRejoin v2.0 | Termux Root"
                },
                timestamp: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
            }]
        }' 2>/dev/null)

    if [ -z "$payload" ]; then
        log_warn "Không tạo được payload webhook"
        return 1
    fi

    # Gửi async (không block main loop)
    curl -s -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -H "User-Agent: RobloxAutoRejoin/2.0" \
        -d "$payload" \
        --max-time 10 \
        &>/dev/null &
}

# ============================================================
#  CÁC LOẠI THÔNG BÁO
# ============================================================

send_webhook_rejoin() {
    local pkg=$1
    local reason=$2
    local notify; notify=$(get_config ".webhook.notify_rejoin")
    [ "$notify" != "true" ] && return

    local fields='[
        {"name":"Package","value":"'"$pkg"'","inline":true},
        {"name":"Lý do","value":"'"$reason"'","inline":true},
        {"name":"Giờ","value":"'"$(date '+%H:%M:%S')"'","inline":true}
    ]'

    send_discord_embed \
        "🔄 Auto Rejoin Triggered" \
        "Game bị ngắt kết nối, đang rejoin..." \
        "16776960" \
        "$fields"
}

send_webhook_success() {
    local pkg=$1
    local attempt=$2
    local notify; notify=$(get_config ".webhook.notify_success")
    [ "$notify" != "true" ] && return

    local total; total=$(get_config ".stats.total_rejoins // 0")
    local fields='[
        {"name":"Package","value":"'"$pkg"'","inline":true},
        {"name":"Lần thử","value":"'"$attempt"'","inline":true},
        {"name":"Tổng rejoins","value":"'"$total"'","inline":true}
    ]'

    send_discord_embed \
        "✅ Rejoin Thành Công!" \
        "Đã vào lại game thành công." \
        "3066993" \
        "$fields"
}

send_webhook_crash() {
    local pkg=$1
    local notify; notify=$(get_config ".webhook.notify_crash")
    [ "$notify" != "true" ] && return

    local max; max=$(get_config ".timing.max_retries // 10")
    local total_crash; total_crash=$(get_config ".stats.total_crashes // 0")

    local fields='[
        {"name":"Package","value":"'"$pkg"'","inline":true},
        {"name":"Thử tối đa","value":"'"$max"' lần","inline":true},
        {"name":"Tổng crash","value":"'"$total_crash"'","inline":true}
    ]'

    send_discord_embed \
        "❌ Rejoin Thất Bại!" \
        "Đã thử hết số lần tối đa mà không vào được game. Cần kiểm tra thủ công!" \
        "15158332" \
        "$fields"
}

send_webhook_started() {
    local pkg=$1
    send_discord_embed \
        "🚀 Auto Rejoin Đã Bật" \
        "Bắt đầu theo dõi game cho package: **$pkg**\nThời gian: $(date '+%Y-%m-%d %H:%M:%S')" \
        "3447003"
}

send_webhook_test() {
    send_discord_embed \
        "🧪 Test Webhook Thành Công!" \
        "Webhook đang hoạt động tốt.\nRoblox AutoRejoin v2.0 đã kết nối." \
        "3066993"
}
