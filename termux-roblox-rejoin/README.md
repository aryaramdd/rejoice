# 🎮 Termux Roblox Auto Rejoin v2.0

> Automatically rejoin Roblox when kicked/disconnected, running in the background in Termux.
> Supports ROOT • Multiple executors • VIP Server • Discord Webhook

---

## 📋 Table of Contents

- [Requirements](#-requirements)
- [Installation (1 command)](#-installation-1-command)
- [Usage](#-usage)
- [Game Configuration](#-game-configuration)
- [Discord Webhook Configuration](#-discord-webhook-configuration)
- [When Delta Updates (package name changes)](#-when-delta-updates-package-name-changes)
- [Troubleshooting](#-troubleshooting)
- [Directory Structure](#-directory-structure)
- [FAQ](#-faq)

---

## 📌 Requirements

| Requirement | Details |
|---------|----------|
| **Root** | Device must be ROOTED (Magisk/KernelSU) |
| **Termux** | Latest version from [F-Droid](https://f-droid.org/packages/com.termux/) |
| **Termux:API** | Termux:API app (download from same place as Termux) |
| **Android** | Android 8.0+ |
| **Roblox** | Any package: official, Delta, Codex, Fluxus... |

> ⚠️ **IMPORTANT**: Use Termux from **F-Droid**, NOT from Google Play (Play Store version is restricted)

---

## ⚡ Installation (1 Command)

Open Termux, paste this command and press Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/aryaramdd/rejoice/main/install.sh | bash
```

**The tool will automatically:**
1. Update Termux packages
2. Install dependencies (curl, git, jq, bc...)
3. Download all script files
4. Create default configuration
5. Create shortcut `rblx` for quick access

**After installation:** Type `rblx` to open the tool!

---

## 🚀 Usage

### First time

```
Step 1: Install the tool (paste the curl command above)
Step 2: Type 'rblx' to open the menu
Step 3: Select 1 → Choose your Roblox package
Step 4: Select 2 → Enter Place ID or VIP link
Step 5: Select 3 → Start Auto Rejoin
```

### Next times

```bash
rblx          # Open main menu
rblx start    # Enable auto rejoin immediately (no menu)
rblx stop     # Disable auto rejoin
rblx status   # View status
rblx log      # View realtime log
```

### Main menu

```
╔══════════════════════════════════════════════════╗
║     🎮  ROBLOX AUTO REJOIN  v2.0  🎮            ║
║          Termux Root Edition                     ║
╚══════════════════════════════════════════════════╝

  Package:  com.roblox.client
  Place ID: 12345678
  Roblox:   ● Running (PID: 1234)
  Monitor:  ● AUTO REJOIN ON (PID: 5678)

  1. 📦 Manage Roblox Package
  2. 🎮 Game Config (Place ID / VIP Link)
  3. ▶  Start Auto Rejoin
  4. ■  Stop Auto Rejoin
  5. 📊 View Status
  6. 🔔 Discord Webhook
  7. ⏱  Timing Settings
  8. ⚙  Advanced
  9. 📋 View Monitor Log (realtime)
  0. 🚪 Exit
```

---

## 🎮 Game Configuration

### Public Game
1. Open Roblox → find the game you want to farm
2. Copy URL: `https://www.roblox.com/games/`**`12345678`**`/Game-Name`
3. Get the ID number (e.g. `12345678`)
4. Open the tool → Menu 2 → Select 1 → Enter ID

### VIP/Private Server
1. Enter the game → Copy VIP link (format `...?privateServerLinkCode=XXXX`)
2. Open the tool → Menu 2 → Select 2 → Paste the full link

### Valid VIP link example
```
https://www.roblox.com/games/12345678/Game-Name?privateServerLinkCode=AbCdEf123456
```

---

## 🔔 Discord Webhook Configuration

### How to get Webhook URL
1. Open Discord → Your server
2. Settings (⚙) → Integrations → Webhooks
3. New Webhook → Copy Webhook URL
4. URL will look like: `https://discord.com/api/webhooks/XXXX/YYYY`

### Setup in the tool
1. Open the tool → Menu 6
2. Select 1 → Paste webhook URL
3. Webhook will be enabled automatically
4. Select 7 to test

### Notification types
- 🔄 **Rejoin Triggered** — When kick is detected
- ✅ **Rejoin Successful** — When rejoining the game succeeds
- ❌ **Rejoin Failed** — When all retries are exhausted

---

## 🔄 When Delta Updates (Package Name Changes)

Delta Executor frequently updates and **changes its package name** on each update. How to handle it:

### Method 1: Auto-detect new package name (easiest)

```
1. Install the new Delta version
2. Open Delta (keep it in foreground)
3. Open Termux → type 'rblx'
4. Menu 8 (Advanced) → select 7 (Find package name)
5. Tool will auto-detect and ask if you want to add it to the list
```

### Method 2: Find manually via command

```bash
# Open Delta, then run this in Termux:
su -c "dumpsys activity activities | grep mCurrentFocus | grep -oE '[a-zA-Z0-9.]+/' | tr -d '/'"
```

### Method 3: Use pm list

```bash
# List all installed packages, filter for Delta:
su -c "pm list packages | grep -i 'delta\|njnj\|vng\|executor'"
```

### After getting the new package name

```
1. Open the tool → Menu 1 → press [A]
2. Enter name: "Delta v1.x"
3. Enter the new package name
4. Press [S] to set as active
```

---

## 🔧 Troubleshooting

### ❌ "Device not ROOTED"

```
✓ Check: Open Magisk → check root status
✓ Grant permission: Magisk → SuperUser → find Termux → Allow
✓ Test: type 'su' in Termux, if prompt changes to # it's ok
```

### ❌ "jq: command not found"

```bash
pkg install jq -y
```

### ❌ Rejoin not working (app doesn't open)

```
Common causes:
1. Wrong Place ID → double-check the ID
2. Wrong package name → use Advanced → Find package name
3. VIP link expired → get a new link
4. Roblox banned → try another account

Quick fix:
1. Menu 8 → Advanced → Kill all Roblox
2. Menu 8 → Clear cache for all
3. Try again
```

### ❌ False detection (rejoin while playing normally)

```
Adjust timing:
→ Menu 7 (Timing Settings)
→ Increase check_interval to 10s
→ Increase cpu_low_duration to 30

Or disable CPU monitor:
→ Edit config.json:
   "use_cpu": false
```

### ❌ Webhook not received

```
1. Check internet: ping google.com
2. Confirm URL is correct (must contain discord.com/api/webhooks/)
3. Try: Menu 6 → Test webhook
4. Check Discord server hasn't deleted the webhook
```

### ❌ Tool fails to install (network error)

```bash
# Manual install:
pkg update -y
pkg install curl git jq bc -y
git clone https://github.com/aryaramdd/rejoice ~/roblox-rejoin
cp ~/roblox-rejoin/config.json.example ~/roblox-rejoin/config/config.json
bash ~/roblox-rejoin/install.sh
```

### ❌ "am start" not working

```
Check root permission:
su -c "am start --help"

If permission denied:
→ Open Magisk → SuperUser → grant Termux permission
→ Restart Termux
```

### ❌ Tool runs but Roblox doesn't join the game

```
Deep link may be blocked on some ROMs:
1. Try opening Roblox manually first
2. Check if Roblox is the default app for roblox:// scheme

Fix:
su -c "am start -a android.intent.action.VIEW -d 'roblox://placeId=12345678'"
→ If it opens → problem is package name
→ If it doesn't open → ROM blocks deep link
```

---

## ⏱ Recommended Timing Settings

| Situation | check_interval | rejoin_delay | cpu_low_duration |
|-----------|----------------|--------------|-----------------|
| **Normal** | 5s | 8s | 20 |
| **Laggy game** | 8s | 12s | 30 |
| **Unstable server** | 3s | 5s | 15 |
| **Battery saver** | 10s | 10s | 40 |

---

## 📁 Directory Structure

```
~/roblox-rejoin/              ← Installation directory
├── main.sh                   ← Main file, entry point
├── config/
│   └── config.json           ← Your configuration
├── logs/
│   └── rejoin_YYYYMMDD.log   ← Daily log
└── lib/
    ├── utils.sh              ← Shared utility functions
    ├── detect.sh             ← Disconnect detection system
    ├── rejoin.sh             ← Rejoin execution logic
    ├── menu.sh               ← Menu interface
    ├── webhook.sh            ← Discord webhook
    └── advanced.sh           ← Advanced features
```

```
repo/                         ← GitHub repo
├── install.sh                ← One-command installer
├── main.sh                   ← Main script
├── config.json.example       ← Example config
├── README.md                 ← This file
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

**Q: Is the tool safe?**
A: The tool only uses standard Android commands (`am`, `dumpsys`, `pm`). No injection, no game modification. Completely client-side.

**Q: Will I get banned by Roblox?**
A: Auto rejoin itself does not violate ToS. However if you use an executor (Delta, Codex...) the executor is the ban reason.

**Q: Does the tool drain battery?**
A: Checking every 5s is lightweight. Logcat monitoring costs a bit more. Set `use_logcat: false` to save battery.

**Q: Can I run multiple packages at once?**
A: Currently only 1 package is monitored at a time (active package). To change → Menu 1 → Select another package.

**Q: Does the tool work when screen is off?**
A: Yes, because it runs in the background in Termux. But make sure Termux is not killed by Android (Install Termux:Boot, or keep Termux in recent tasks).

**Q: How to update the tool?**
```bash
cd ~/roblox-rejoin
git pull
# Or run the installer again:
curl -fsSL https://raw.githubusercontent.com/aryaramdd/rejoice/main/install.sh | bash
```

**Q: How to uninstall the tool?**
```bash
rm -rf ~/roblox-rejoin
rm -f "$PREFIX/bin/rblx"
# Remove alias in ~/.bashrc if any
```

---

## 📝 Changelog

### v2.0.0
- Multi-layer detection system (5 methods)
- Discord webhook with nice embeds
- Completely new, more professional menu
- Advanced menu: auto package finder, auto boot
- Detailed timing config
- Automatic daily logging

### v1.0.0
- Initial release

---

## ⚠️ Disclaimer

This tool is for educational and research purposes only.
Using the tool together with executors that violate Roblox ToS is the user's responsibility.
The author is not responsible for account bans.

---

*Made with ❤️ for the Roblox Termux community*
