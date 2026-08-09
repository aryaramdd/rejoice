# Package List - Roblox Executor Package Names

> Updated regularly. If package name changes, find it via Advanced -> Menu 7.

## Official Roblox
| Name | Package Name | Notes |
|-----|-------------|---------|
| Roblox Official | `com.roblox.client` | Stable, rarely changes |

## Popular Executors
| Name | Package Name (latest) | Notes |
|-----|------------------------|---------|
| Delta Executor | `com.vng.njnj` | **Changes frequently!** |
| Delta Executor (old) | `com.delta.executor` | Old version |
| Codex | `com.codex.client` | |
| Fluxus | `com.fluxteam.fluxus` | |
| Arceus X Neo | `com.arceusx.neo` | |
| Hydrogen | `com.hydrogen.executor` | |
| Vegax | `com.vegax.android` | |

## Important Note

### Delta Executor changes package name very frequently!

**How to find new package name after each Delta update:**

```bash
# Open Delta, then run this command:
su -c "dumpsys activity activities | grep mCurrentFocus"
# Result: mCurrentFocus=Window{... com.PACKAGE.NAME/com.PACKAGE.NAME.MainActivity}
#                                       ^^^^^^^^^^^^^^^^ this is the package name
```

**Or use the tool menu:**
```
rblx -> Menu 8 (Advanced) -> Select 7 (Find package name of running app)
```

## How to Verify Package Name
```bash
# Check if package is installed:
su -c "pm path com.your.package.name"
# If result exists -> installed
# If not -> not installed or wrong package name
```
