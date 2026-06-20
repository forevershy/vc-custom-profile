# Publish to GitHub (one-time setup)

Repo: **https://github.com/forevershy/vc-custom-profile**

After you push updates, friends install with **one command** (share this link):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm 'https://raw.githubusercontent.com/forevershy/vc-custom-profile/master/install-easy.ps1')"
```

Or send them **[INSTALL-FRIEND.md](INSTALL-FRIEND.md)** on GitHub.

---

## Push your changes

```powershell
cd C:\Users\jwalt\vc-custom-profile
git add -A
git commit -m "Describe your changes"
git push
```

Friends re-run the one-liner above to update.

---

## First-time publish (already done)

If you ever need to recreate the repo:

```powershell
cd C:\Users\jwalt\vc-custom-profile
powershell -ExecutionPolicy Bypass -File publish-to-github.ps1
```

---

## Keep plugin folder in sync

When you edit inside Vencord, copy changes back before pushing:

```powershell
Copy-Item "C:\Users\jwalt\Vencord\src\userplugins\vc-custom-profile\*" "C:\Users\jwalt\vc-custom-profile\" -Recurse -Force
```

Or edit directly in `C:\Users\jwalt\vc-custom-profile` and copy into Vencord before rebuilding.
