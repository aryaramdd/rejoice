# 🎮 Termux Roblox Auto Rejoin v2.0

> Tool tự động rejoin Roblox khi bị kick/disconnect, chạy ngầm trong Termux.  
> Hỗ trợ ROOT • Nhiều executor • VIP Server • Discord Webhook

---

## 📋 Mục Lục

- [Yêu cầu](#-yêu-cầu)
- [Cài đặt (1 lệnh)](#-cài-đặt-1-lệnh)
- [Hướng dẫn sử dụng](#-hướng-dẫn-sử-dụng)
- [Cấu hình game](#-cấu-hình-game)
- [Cấu hình webhook Discord](#-cấu-hình-webhook-discord)
- [Khi Delta update (đổi package name)](#-khi-delta-update-đổi-package-name)
- [Troubleshooting](#-troubleshooting)
- [Cấu trúc thư mục](#-cấu-trúc-thư-mục)
- [FAQ](#-faq)

---

## 📌 Yêu Cầu

| Yêu cầu | Chi tiết |
|---------|----------|
| **Root** | Thiết bị phải đã ROOT (Magisk/KernelSU) |
| **Termux** | Phiên bản mới nhất từ [F-Droid](https://f-droid.org/packages/com.termux/) |
| **Termux:API** | App Termux:API (tải cùng chỗ với Termux) |
| **Android** | Android 8.0+ |
| **Roblox** | Bất kỳ package nào: gốc, Delta, Codex, Fluxus... |

> ⚠️ **QUAN TRỌNG**: Dùng Termux từ **F-Droid**, KHÔNG dùng từ Google Play (phiên bản Play bị giới hạn)

---

## ⚡ Cài Đặt (1 Lệnh)

Mở Termux, paste lệnh này và nhấn Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB/termux-roblox-rejoin/main/install.sh | bash
```

**Tool sẽ tự động:**
1. Cập nhật Termux packages
2. Cài dependencies (curl, git, jq, bc...)
3. Download tất cả script files
4. Tạo cấu hình mặc định
5. Tạo shortcut `rblx` để dùng nhanh

**Sau khi cài xong:** Gõ `rblx` để mở tool!

---

## 🚀 Hướng Dẫn Sử Dụng

### Lần đầu tiên

```
Bước 1: Cài tool (paste lệnh curl ở trên)
Bước 2: Gõ 'rblx' để mở menu
Bước 3: Chọn 1 → Chọn package Roblox của bạn
Bước 4: Chọn 2 → Nhập Place ID hoặc VIP link
Bước 5: Chọn 3 → Bắt đầu Auto Rejoin
```

### Từ lần sau

```bash
rblx          # Mở menu chính
rblx start    # Bật auto rejoin ngay (không cần menu)
rblx stop     # Tắt auto rejoin
rblx status   # Xem trạng thái
rblx log      # Xem log realtime
```

### Menu chính

```
╔══════════════════════════════════════════════════╗
║     🎮  ROBLOX AUTO REJOIN  v2.0  🎮            ║
║          Termux Root Edition                     ║
╚══════════════════════════════════════════════════╝

  Package:  com.roblox.client
  Place ID: 12345678
  Roblox:   ● Đang chạy (PID: 1234)
  Monitor:  ● AUTO REJOIN BẬT (PID: 5678)

  1. 📦 Quản lý Package Roblox
  2. 🎮 Config Game (Place ID / VIP Link)
  3. ▶  Bắt đầu Auto Rejoin
  4. ■  Dừng Auto Rejoin
  5. 📊 Xem Status
  6. 🔔 Webhook Discord
  7. ⏱  Cài Timing
  8. ⚙  Advanced
  9. 📋 Xem Monitor Log (realtime)
  0. 🚪 Thoát
```

---

## 🎮 Cấu Hình Game

### Public Game
1. Vào Roblox → tìm game muốn farm
2. Copy URL: `https://www.roblox.com/games/`**`12345678`**`/Ten-Game`
3. Lấy số ID (ví dụ: `12345678`)
4. Mở tool → Menu 2 → Chọn 1 → Nhập ID

### VIP/Private Server
1. Vào game → Copy VIP link (dạng `...?privateServerLinkCode=XXXX`)
2. Mở tool → Menu 2 → Chọn 2 → Paste toàn bộ link

### Ví dụ VIP link hợp lệ
```
https://www.roblox.com/games/12345678/Game-Name?privateServerLinkCode=AbCdEf123456
```

---

## 🔔 Cấu Hình Webhook Discord

### Cách lấy Webhook URL
1. Mở Discord → Server của bạn
2. Settings (⚙) → Integrations → Webhooks
3. New Webhook → Copy Webhook URL
4. URL sẽ có dạng: `https://discord.com/api/webhooks/XXXX/YYYY`

### Cài trong tool
1. Mở tool → Menu 6
2. Chọn 1 → Paste webhook URL
3. Webhook sẽ tự bật
4. Chọn 7 để test

### Các loại thông báo
- 🔄 **Rejoin Triggered** — Khi phát hiện bị kick
- ✅ **Rejoin Thành Công** — Khi vào lại game thành công
- ❌ **Rejoin Thất Bại** — Khi thử hết số lần

---

## 🔄 Khi Delta Update (Đổi Package Name)

Delta Executor thường xuyên cập nhật và **đổi package name** mỗi lần update. Đây là cách xử lý:

### Cách 1: Tự tìm package name mới (dễ nhất)

```
1. Cài Delta phiên bản mới
2. Mở Delta lên (để nó ở foreground)
3. Mở Termux → gõ 'rblx'
4. Menu 8 (Advanced) → chọn 7 (Tìm package name)
5. Tool tự detect và hỏi có muốn thêm vào list không
```

### Cách 2: Tìm thủ công bằng command

```bash
# Mở Delta lên, sau đó chạy lệnh này trong Termux:
su -c "dumpsys activity activities | grep mCurrentFocus | grep -oE '[a-zA-Z0-9.]+/' | tr -d '/'"
```

### Cách 3: Dùng pm list

```bash
# Liệt kê tất cả package đã cài, lọc tìm Delta:
su -c "pm list packages | grep -i 'delta\|njnj\|vng\|executor'"
```

### Sau khi có package name mới

```
1. Mở tool → Menu 1 → nhấn [A]
2. Nhập tên: "Delta v1.x"
3. Nhập package name mới
4. Nhấn [S] để chọn làm active
```

---

## 🔧 Troubleshooting

### ❌ "Thiết bị chưa ROOT"

```
✓ Kiểm tra: Mở Magisk → kiểm tra trạng thái root
✓ Cấp quyền: Magisk → SuperUser → tìm Termux → Allow
✓ Test: gõ 'su' trong Termux, nếu prompt đổi thành # là ok
```

### ❌ "jq: command not found"

```bash
pkg install jq -y
```

### ❌ Rejoin không hoạt động (app không mở)

```
Nguyên nhân thường gặp:
1. Place ID sai → kiểm tra lại số ID
2. Package name sai → dùng Advanced → Tìm package name
3. VIP link hết hạn → lấy link mới
4. Roblox bị ban → thử đổi account

Fix nhanh:
1. Menu 8 → Advanced → Kill tất cả Roblox
2. Menu 8 → Xoá cache tất cả
3. Thử lại
```

### ❌ Phát hiện sai (rejoin khi đang chơi bình thường)

```
Điều chỉnh timing:
→ Menu 7 (Cài Timing)
→ Tăng check_interval lên 10s
→ Tăng cpu_low_duration lên 30

Hoặc tắt CPU monitor:
→ Chỉnh file config.json:
   "use_cpu": false
```

### ❌ Webhook không nhận được

```
1. Kiểm tra internet: ping google.com
2. Xác nhận URL đúng (phải có discord.com/api/webhooks/)
3. Thử: Menu 6 → Test webhook
4. Kiểm tra Discord server chưa bị xoá webhook
```

### ❌ Tool không cài được (lỗi mạng)

```bash
# Cài thủ công:
pkg update -y
pkg install curl git jq bc -y
git clone https://github.com/YOUR_GITHUB/termux-roblox-rejoin ~/roblox-rejoin
cp ~/roblox-rejoin/config.json.example ~/roblox-rejoin/config/config.json
bash ~/roblox-rejoin/install.sh
```

### ❌ "am start" không hoạt động

```
Kiểm tra quyền root:
su -c "am start --help"

Nếu lỗi permission denied:
→ Mở Magisk → SuperUser → cấp quyền Termux
→ Restart Termux
```

### ❌ Tool chạy nhưng Roblox không vào game

```
Deep link có thể bị chặn ở một số ROM:
1. Thử mở Roblox thủ công trước
2. Kiểm tra Roblox có phải default app cho roblox:// scheme không

Fix:
su -c "am start -a android.intent.action.VIEW -d 'roblox://placeId=12345678'"
→ Nếu mở được → problem ở package name
→ Nếu không mở → ROM chặn deep link
```

---

## ⏱ Cài Đặt Timing Khuyến Nghị

| Tình huống | check_interval | rejoin_delay | cpu_low_duration |
|-----------|----------------|--------------|-----------------|
| **Bình thường** | 5s | 8s | 20 |
| **Game hay lag** | 8s | 12s | 30 |
| **Server không ổn định** | 3s | 5s | 15 |
| **Pin tiết kiệm** | 10s | 10s | 40 |

---

## 📁 Cấu Trúc Thư Mục

```
~/roblox-rejoin/              ← Thư mục cài đặt
├── main.sh                   ← File chính, điểm vào
├── config/
│   └── config.json           ← Cấu hình của bạn
├── logs/
│   └── rejoin_YYYYMMDD.log   ← Log hàng ngày
└── lib/
    ├── utils.sh              ← Hàm tiện ích chung
    ├── detect.sh             ← Hệ thống phát hiện disconnect
    ├── rejoin.sh             ← Logic thực hiện rejoin
    ├── menu.sh               ← Giao diện menu
    ├── webhook.sh            ← Discord webhook
    └── advanced.sh           ← Tính năng nâng cao
```

```
repo/                         ← Thư mục GitHub repo
├── install.sh                ← Installer 1 lệnh
├── main.sh                   ← Script chính
├── config.json.example       ← Config mẫu
├── README.md                 ← File này
└── lib/
    ├── utils.sh
    ├── detect.sh
    ├── rejoin.sh
    ├── menu.sh
    ├── webhook.sh
    └── advanced.sh
```

---

## ❓ FAQ

**Q: Tool có an toàn không?**  
A: Tool chỉ dùng các lệnh Android tiêu chuẩn (`am`, `dumpsys`, `pm`). Không inject, không chỉnh game. Hoàn toàn client-side.

**Q: Có bị Roblox ban không?**  
A: Auto rejoin bản thân không vi phạm ToS. Tuy nhiên nếu dùng executor (Delta, Codex...) thì executor mới là nguyên nhân ban.

**Q: Tool có tốn pin không?**  
A: Check mỗi 5s = nhẹ. Logcat monitor tốn hơn một chút. Tắt `use_logcat: false` để tiết kiệm pin.

**Q: Có thể chạy nhiều package cùng lúc không?**  
A: Hiện tại mỗi lần chỉ monitor 1 package (active package). Muốn đổi → Menu 1 → Chọn package khác.

**Q: Tool có hoạt động khi tắt màn hình không?**  
A: Có, vì chạy ngầm trong Termux. Nhưng đảm bảo Termux không bị Android kill (Cài Termux:Boot, hoặc giữ Termux trong recent tasks).

**Q: Làm sao cập nhật tool?**  
```bash
cd ~/roblox-rejoin
git pull
# Hoặc chạy lại installer:
curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
```

**Q: Xoá tool như thế nào?**  
```bash
rm -rf ~/roblox-rejoin
rm -f "$PREFIX/bin/rblx"
# Xoá alias trong ~/.bashrc nếu có
```

---

## 📝 Changelog

### v2.0.0
- Hệ thống detect đa lớp (5 phương pháp)
- Discord webhook với embed đẹp
- Menu hoàn toàn mới, chuyên nghiệp hơn
- Advanced menu: tìm package tự động, auto boot
- Timing config chi tiết
- Log hàng ngày tự động

### v1.0.0
- Bản đầu tiên

---

## ⚠️ Disclaimer

Tool này chỉ phục vụ mục đích học tập và nghiên cứu.  
Sử dụng tool cùng với các executor vi phạm Roblox ToS là trách nhiệm của người dùng.  
Tác giả không chịu trách nhiệm về việc account bị ban.

---

*Made with ❤️ for the Roblox Termux community*
