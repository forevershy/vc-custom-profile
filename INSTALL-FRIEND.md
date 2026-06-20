# Install CustomProfile

**One command. No zip. No git. Works on Windows.**

## Step 1 — Open PowerShell

Important:
- Open **PowerShell** (search "PowerShell" in Start menu)
- **Not** Command Prompt
- **Not** the Run dialog inside Discord

## Step 2 — Paste and run

Copy this whole line, paste into PowerShell, press Enter:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm 'https://raw.githubusercontent.com/forevershy/vc-custom-profile/master/install-easy.ps1')"
```

The first run can take **5–15 minutes** (downloads Vencord, Node tools, builds everything). That is normal.

## Step 3 — Enable the plugin

1. Open Discord
2. **Settings → Vencord → Plugins**
3. Enable **CustomProfile**
4. Restart Discord

If you do not see **Vencord** in Settings, the install did not finish — see Troubleshooting below.

---

## Easier backup method (if the command fails)

1. Go to https://github.com/forevershy/vc-custom-profile
2. Click green **Code** → **Download ZIP**
3. Unzip the folder
4. Double-click **`install.bat`**
5. Enable **CustomProfile** in Vencord settings and restart Discord

---

## Troubleshooting

### "irm is not recognized" or "iex is not recognized"
You are in **Command Prompt**, not PowerShell. Open PowerShell and try again.

### "Running scripts is disabled on this system"
Use this command instead (includes Bypass):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm 'https://raw.githubusercontent.com/forevershy/vc-custom-profile/master/install-easy.ps1')"
```

### "winget is not available" or Git/Node install fails
Install these manually, then run the install command again:
- **Git:** https://git-scm.com/download/win
- **Node.js LTS:** https://nodejs.org

### Install failed partway through
1. Close PowerShell
2. Open a **new** PowerShell window
3. Run the install command again

If it still fails, send your friend the log file:
```
%TEMP%\customprofile-install.log
```
(Press Win+R, paste that path, press Enter)

### Discord opens but there is no Vencord tab
- Make sure you opened the **same Discord** you installed to (regular vs PTB vs Canary)
- Run the installer again
- Try the zip + **install.bat** method above

### CustomProfile is not in the plugin list
- Settings → Vencord → Plugins → search **CustomProfile**
- Make sure it is enabled, then **restart Discord**

### Microsoft Store Discord
The installer tries auto-detect for Store installs. If it still fails, install regular Discord from https://discord.com/download and run the installer again.

---

## Updating

Run the same install command again, or download the latest zip and run **install.bat**.

---

## Notes

- **Only you see the fake profile** — changes are client-side only
- Only install from repos you trust
