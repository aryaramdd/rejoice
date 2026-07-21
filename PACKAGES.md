# 📦 Danh Sách Package Name Roblox Executor

> Cập nhật thường xuyên. Nếu package name đổi, tìm bằng Advanced → Menu 7.

## Roblox Gốc
| Tên | Package Name | Ghi chú |
|-----|-------------|---------|
| Roblox Official | `com.roblox.client` | Stable, ít thay đổi |

## Executor Phổ Biến
| Tên | Package Name (mới nhất) | Ghi chú |
|-----|------------------------|---------|
| Delta Executor | `com.vng.njnj` | **Thay đổi thường xuyên!** |
| Delta Executor (cũ) | `com.delta.executor` | Phiên bản cũ |
| Codex | `com.codex.client` | |
| Fluxus | `com.fluxteam.fluxus` | |
| Arceus X Neo | `com.arceusx.neo` | |
| Hydrogen | `com.hydrogen.executor` | |
| Vegax | `com.vegax.android` | |

## ⚠️ Lưu Ý Quan Trọng

### Delta Executor thay đổi package name rất thường xuyên!

**Cách tìm package name mới sau mỗi lần Delta update:**

```bash
# Mở Delta lên, sau đó chạy lệnh này:
su -c "dumpsys activity activities | grep mCurrentFocus"
# Kết quả: mCurrentFocus=Window{... com.PACKAGE.NAME/com.PACKAGE.NAME.MainActivity}
#                                       ^^^^^^^^^^^^^^^^ đây là package name
```

**Hoặc dùng menu tool:**
```
rblx → Menu 8 (Advanced) → Chọn 7 (Tìm package name app đang chạy)
```

## Cách Verify Package Name
```bash
# Kiểm tra package đã cài chưa:
su -c "pm path com.your.package.name"
# Nếu có kết quả → đã cài
# Nếu không → chưa cài hoặc package name sai
```
