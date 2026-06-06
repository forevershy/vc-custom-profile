/*
 * CustomProfile - Client-side profile customization for Vencord
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import "./styles.css";

import { NavContextMenuPatchCallback } from "@api/ContextMenu";
import definePlugin from "@utils/types";
import { Menu, UserStore } from "@webpack/common";

import { openEditor, settings, getProfile } from "./settings";
import {
    applyProfileChanges,
    clearBadges,
    getAvatarDecoration,
    getCustomDisplayName,
    installCreationDateOverride,
    patchUser,
    patchUserProfile,
    registerBadgeProvider,
    uninstallCreationDateOverride,
} from "./utils";
import { buildNativeProfileBadges } from "./badges";

const SelfContextMenu: NavContextMenuPatchCallback = (children, { user }) => {
    if (!user || user.id !== UserStore.getCurrentUser()?.id) return;

    children.push(
        <Menu.MenuGroup>
            <Menu.MenuItem
                id="vc-custom-profile-open"
                label="Custom Profile"
                action={openEditor}
            />
        </Menu.MenuGroup>
    );
};

export default definePlugin({
    name: "CustomProfile",
    description: "Customize your profile locally — fake badges, username, nitro tier, boost badge, and avatar decorations. Only visible to you.",
    authors: [{ name: "Custom", id: 0n }],
    tags: ["Customisation", "Fun", "Profile"],
    dependencies: ["BadgeAPI"],

    settings,

    toolboxActions: {
        "Open Custom Profile": openEditor,
    },

    contextMenus: {
        "user-context": SelfContextMenu,
    },

    patches: [
        {
            find: ".getCurrentUser()",
            replacement: {
                match: /getUser\((\i)\)\{([\s\S]+?)return (\i);/,
                replace: "getUser($1){$2return $self.patchUserResult($3);",
            },
        },
        {
            find: ".getCurrentUser()",
            replacement: {
                match: /getCurrentUser\(\)\{([\s\S]+?)return (\i);/,
                replace: "getCurrentUser(){$1return $self.patchUserResult($2);",
            },
        },
        {
            find: ".useName(",
            replacement: {
                match: /(?<=function \i\(\i\)\{)(?=let)/,
                replace: "const _vcCpName=$self.getDisplayNameOverride(arguments[0]);if(_vcCpName!=null)return _vcCpName;",
            },
        },
        {
            find: ".getGlobalName(",
            replacement: {
                match: /getGlobalName\((\i)\)\{/,
                replace: "getGlobalName($1){const _vcCp=$self.getGlobalNameOverride($1);if(_vcCp!=null)return _vcCp;",
            },
        },
        {
            find: "isAvatarDecorationAnimating:",
            group: true,
            replacement: [
                {
                    match: /(?<=\.avatarDecoration,guildId:\i\}\)\),)(?<=user:(\i).+?)/,
                    replace: "vcCustomProfileDecoration=$self.getAvatarDecorationForUser($1),",
                },
                {
                    match: /(?<={avatarDecoration:).{1,30}?(?=,)(?<=avatarDecorationOverride:(\i).+?)/,
                    replace: "$1??vcCustomProfileDecoration??($&)",
                },
                {
                    match: /(?<=size:\i}\),\[)/,
                    replace: "vcCustomProfileDecoration,",
                },
            ],
        },
        {
            find: "UserProfileStore",
            replacement: {
                match: /(?<=getUserProfile\(\i\){return )(.+?)(?=})/,
                replace: "$self.profilePatchHook($1)",
            },
        },
        {
            find: "getLegacyUsername(){",
            replacement: {
                match: /getBadges\(\)\{/,
                replace: "getBadges(){const _vcCpOnly=$self.getBadgesOverride(this);if(_vcCpOnly!=null)return _vcCpOnly;",
            },
        },
    ],

    flux: {
        CONNECTION_OPEN() {
            applyProfileChanges();
        },
    },

    start() {
        registerBadgeProvider();
        installCreationDateOverride();
        applyProfileChanges();
    },

    stop() {
        clearBadges();
        uninstallCreationDateOverride();
    },

    patchUserResult<T extends { id?: string; } | null | undefined>(user: T): T {
        return patchUser(user as any) as T;
    },

    getAvatarDecorationForUser(user: { id?: string; }) {
        if (!user?.id || user.id !== UserStore.getCurrentUser()?.id) return null;
        return getAvatarDecoration();
    },

    getDisplayNameOverride(user: { id?: string; }) {
        if (!user?.id || user.id !== UserStore.getCurrentUser()?.id) return null;
        const name = getCustomDisplayName();
        return name || null;
    },

    getGlobalNameOverride(user: { id?: string; username?: string; globalName?: string | null; }) {
        if (!user?.id || user.id !== UserStore.getCurrentUser()?.id) return null;
        const name = getCustomDisplayName();
        return name || null;
    },

    profilePatchHook(profile: Parameters<typeof patchUserProfile>[0]) {
        return patchUserProfile(profile);
    },

    getBadgesOverride(profile: { userId?: string; }) {
        if (profile?.userId !== UserStore.getCurrentUser()?.id) return null;
        if (!getProfile().replaceRealBadges) return null;
        return buildNativeProfileBadges(getProfile());
    },
});
