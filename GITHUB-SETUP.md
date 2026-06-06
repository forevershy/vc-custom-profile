# Publish to GitHub (one-time setup)

Follow these steps once. After that, updating is just `git push`.

---

## Step 1 — Log into GitHub

Open PowerShell and run:

```powershell
gh auth login
```

Choose:
- **GitHub.com**
- **HTTPS**
- **Login with a web browser** (easiest)

---

## Step 2 — Create the repo and push

In PowerShell:

```powershell
cd C:\Users\jwalt\vc-custom-profile
powershell -ExecutionPolicy Bypass -File publish-to-github.ps1
```

Or do it manually:

```powershell
cd C:\Users\jwalt\vc-custom-profile
gh repo create vc-custom-profile --public --source=. --remote=origin --push
```

If the repo name is taken, pick another (e.g. `vc-custom-profile-plugin`).

---

## Step 3 — Share with friends

Send them your repo link, for example:

`https://github.com/YOUR_USERNAME/vc-custom-profile`

They run this in PowerShell (**Discord closed**):

```powershell
git clone https://github.com/YOUR_USERNAME/vc-custom-profile.git; cd vc-custom-profile; powershell -ExecutionPolicy Bypass -File install.ps1
```

Replace `YOUR_USERNAME` with your GitHub username.

Also send them **`INSTALL-FRIEND.md`** or link them to it on GitHub.

---

## Updating the plugin later

After you change files:

```powershell
cd C:\Users\jwalt\vc-custom-profile
git add -A
git commit -m "Describe your changes"
git push
```

Friends re-run the install command to get updates.

---

## Optional — keep Vencord copy in sync

When you edit the plugin inside Vencord, copy changes back before pushing:

```powershell
Copy-Item "C:\Users\jwalt\Vencord\src\userplugins\vc-custom-profile\*" "C:\Users\jwalt\vc-custom-profile\" -Recurse -Force
```

Or edit directly in `C:\Users\jwalt\vc-custom-profile` and copy into Vencord before rebuilding.
