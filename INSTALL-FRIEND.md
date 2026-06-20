# Install CustomProfile

**One command. No zip. No git. Works on Windows.**

## Step 1 — Paste in PowerShell

Open **PowerShell**, paste this, press Enter:

```powershell
irm https://raw.githubusercontent.com/forevershy/vc-custom-profile/master/install-easy.ps1 | iex
```

The installer handles everything: closes Discord, downloads the plugin, sets up Vencord, and patches every Discord on your PC.

First run can take a few minutes.

## Step 2 — Enable the plugin

1. Open Discord
2. **Settings → Vencord → Plugins**
3. Enable **CustomProfile**
4. Restart Discord

Open the editor: **Plugins → CustomProfile → Open Custom Profile Editor**

---

## Other ways to install

| Method | How |
|--------|-----|
| **One command** (above) | Best for most people |
| **Download zip** | GitHub → Code → Download ZIP → unzip → double-click `install.bat` |
| **Only Discord PTB** | `& ([scriptblock]::Create((irm https://raw.githubusercontent.com/forevershy/vc-custom-profile/master/install-easy.ps1))) -DiscordBranch ptb` |

---

## Updating

Run the same one-liner again:

```powershell
irm https://raw.githubusercontent.com/forevershy/vc-custom-profile/master/install-easy.ps1 | iex
```

---

## Notes

- **Only you see the fake profile** — changes are client-side only
- Only install from repos you trust
- If Discord updates break the plugin, run the install command again
