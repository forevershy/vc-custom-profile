# CustomProfile — Vencord User Plugin

A **client-side only** Vencord plugin that lets you customize how **your own** profile appears on your Discord client. Pick any official Discord badge, set a custom username/display name, choose a nitro tier badge, boost badge, and avatar decoration.

**Only you see these changes.** Nothing is sent to Discord's servers.

Inspired by profile customization plugins like [fakeProfile](https://github.com/gujarathisampath/fakeProfile), but fully local with no external API or Discord server required.

## Install (Windows)

**Copy this into PowerShell and press Enter:**

```powershell
irm https://raw.githubusercontent.com/forevershy/vc-custom-profile/master/install-easy.ps1 | iex
```

That's it. The installer downloads everything, sets up Vencord, and patches Discord (stable, PTB, and Canary if you have them).

Then: **Settings → Vencord → Plugins → enable CustomProfile → restart Discord**

More options: see **[INSTALL-FRIEND.md](INSTALL-FRIEND.md)**

## Features

- **All official profile badges** — Staff, Partner, HypeSquad, Early Supporter, Verified Developer, Active Developer, and more
- **Custom username & display name** — shown locally on your client
- **Evolving Nitro badge tiers** — Nitro through Opal
- **Server Boost badge tiers** — 1–24 months
- **Special badges** — Quest, Orbs, legacy username style badges
- **Avatar decorations** — preset grid + custom asset ID input
- **Replace real badges** — optionally hide your real badges and show only your fakes

## Requirements

- [Vencord built from source](https://docs.vencord.dev/installing/)
- `BadgeAPI` (enabled automatically as a dependency)

## Installation (developers)

### Manual install

1. Clone or build Vencord from source if you haven't already:
   ```bash
   git clone https://github.com/Vendicated/Vencord.git
   cd Vencord
   pnpm install
   ```

2. Create the userplugins folder (if it doesn't exist):
   ```bash
   mkdir src/userplugins
   ```

3. Copy this entire `vc-custom-profile` folder into `src/userplugins/`:
   ```
   Vencord/src/userplugins/vc-custom-profile/
     index.tsx
     settings.tsx
     badges.ts
     decorations.ts
     decorations.json
     utils.ts
     styles.css
     install.ps1
     components/
       CustomProfileModal.tsx
   ```

4. Build and inject:
   ```bash
   pnpm build
   pnpm inject
   ```

5. Restart Discord, go to **Settings → Vencord → Plugins**, enable **CustomProfile**, and restart again.

## Usage

Open the editor any of these ways:

- **Vencord Settings → Plugins → CustomProfile → Open Custom Profile Editor**
- **Vencord Toolbox → Open Custom Profile**
- **Right-click your own avatar → Custom Profile**

Pick badges, names, nitro/boost tiers, and decorations, then click **Save**. Press `Ctrl+R` to reload Discord if changes don't show immediately.

### Custom avatar decoration asset ID

To use any Discord shop decoration, open Discord's decoration picker, inspect a decoration image in DevTools, and copy the asset hash from the CDN URL:

```
https://cdn.discordapp.com/avatar-decoration-presets/a_YOUR_ASSET_HERE.png
```

Paste `a_YOUR_ASSET_HERE` into the **Custom Decoration Asset ID** field.

## How it works

- Patches `UserStore.getUser` / `getCurrentUser` to override `publicFlags`, `username`, `globalName`, and `premiumType` for your account only
- Uses Vencord's **BadgeAPI** to inject nitro tier, boost, and special badges with official CDN icons
- Patches avatar decoration rendering so decorations appear on your profile and avatars locally

## Disclaimer

- This is **cosmetic and local only** — other users still see your real profile
- Modifying Discord clients may violate Discord's Terms of Service; use at your own risk
- Discord updates can break webpack patches; if the plugin stops working after an update, check for plugin updates or report issues

## License

GPL-3.0-or-later (same as Vencord)
