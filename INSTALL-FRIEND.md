# Easy install (for friends)

Pick **one** of these methods.

---

## Option A — Install from GitHub link (easiest)

Your friend only needs this link and one command.

1. **Close Discord completely**
2. Open **PowerShell**
3. Paste and run (replace `YOUR_GITHUB_USERNAME` with the repo owner):

```powershell
git clone https://github.com/YOUR_GITHUB_USERNAME/vc-custom-profile.git; cd vc-custom-profile; powershell -ExecutionPolicy Bypass -File install.ps1
```

4. Open Discord → **Settings → Vencord → Plugins** → enable **CustomProfile** → restart Discord

---

## Option B — Download zip from GitHub

1. Go to the repo on GitHub
2. Click **Code** → **Download ZIP**
3. Unzip the folder
4. **Close Discord**
5. Right-click **`install.ps1`** → **Run with PowerShell**
6. Enable **CustomProfile** in Vencord settings and restart Discord

---

## If Windows blocks the script

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

---

## Updating

**GitHub command method:** run the same clone/install command again (or pull if they kept the folder).

**Zip method:** download the latest zip and run `install.ps1` again.

---

## Important

- **Only you see the fake profile** — it's client-side only
- **Trust who you get this from** — only run scripts from people/repos you trust
- If Discord updates break the plugin, install again from the latest GitHub version
