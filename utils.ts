/*
 * CustomProfile - Profile patching utilities
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { addProfileBadge, BadgePosition, ProfileBadge, removeProfileBadge } from "@api/Badges";
import type { User } from "@vencord/discord-types";
import { waitFor } from "@webpack";
import { FluxDispatcher, UserStore } from "@webpack/common";

import {
    badgeIcon,
    BOOST_TIERS,
    buildNativeProfileBadges,
    computePublicFlags,
    monthsToPremiumSince,
    NITRO_TIERS,
    PROFILE_BADGES,
    SPECIAL_BADGES,
} from "./badges";
import { CUSTOM_DECORATION_SKU } from "./decorations";
import { getProfile } from "./settings";
import virtualMerge from "virtual-merge";
import type { UserProfile } from "@vencord/discord-types";

let badgeRegistration: ProfileBadge | null = null;

export function getCurrentUserId(): string | undefined {
    return UserStore.getCurrentUser()?.id;
}

export function isSelf(userId: string | null | undefined): boolean {
    if (!userId) return false;
    return userId === getCurrentUserId();
}

export function getCustomUsername(): string {
    return getProfile().customUsername.trim();
}

export function getCustomDisplayName(): string {
    const profile = getProfile();
    return profile.customDisplayName.trim() || profile.customUsername.trim();
}

export function getCustomAccountCreationTimestamp(): number | null {
    const date = getProfile().customAccountCreationDate.trim();
    if (!date) return null;

    const parsed = Date.parse(`${date}T12:00:00`);
    return Number.isNaN(parsed) ? null : parsed;
}

export function getCreationTimestampOverride(snowflake: string): number | null {
    if (!isSelf(snowflake)) return null;
    return getCustomAccountCreationTimestamp();
}

let originalExtractTimestamp: ((snowflake: string) => number) | null = null;
let patchedSnowflakeUtils: { extractTimestamp: (snowflake: string) => number; } | null = null;

export function installCreationDateOverride() {
    waitFor(["fromTimestamp", "extractTimestamp"], snowflakeUtils => {
        if (originalExtractTimestamp) return;

        patchedSnowflakeUtils = snowflakeUtils;
        originalExtractTimestamp = snowflakeUtils.extractTimestamp.bind(snowflakeUtils);
        snowflakeUtils.extractTimestamp = (snowflake: string) => {
            const override = getCreationTimestampOverride(snowflake);
            return override ?? originalExtractTimestamp!(snowflake);
        };
    });
}

export function uninstallCreationDateOverride() {
    if (!originalExtractTimestamp || !patchedSnowflakeUtils) return;

    patchedSnowflakeUtils.extractTimestamp = originalExtractTimestamp;
    originalExtractTimestamp = null;
    patchedSnowflakeUtils = null;
}

export function shouldReplaceRealBadges(): boolean {
    return getProfile().replaceRealBadges;
}

export function getComputedPublicFlags(): number {
    const profile = getProfile();
    const fakeFlags = computePublicFlags(profile.selectedBadges);
    if (profile.replaceRealBadges) return fakeFlags;

    const realUser = UserStore.getCurrentUser();
    const realFlags = realUser?.publicFlags ?? 0;
    return realFlags | fakeFlags;
}

export function getPremiumType(): number {
    const profile = getProfile();
    if (profile.replaceRealBadges) {
        return profile.nitroTier !== "none" ? 2 : 0;
    }
    const { nitroTier } = profile;
    if (nitroTier === "none") return UserStore.getCurrentUser()?.premiumType ?? 0;
    return 2;
}

export function getAvatarDecoration(): { asset: string; skuId: string; } | null {
    const { avatarDecoration } = getProfile();
    if (!avatarDecoration) return null;
    return { asset: avatarDecoration, skuId: CUSTOM_DECORATION_SKU };
}

function buildBadgesForUser(userId: string): ProfileBadge[] {
    if (userId !== getCurrentUserId()) return [];
    // When replacing, badges come from profile store / getBadges filter instead
    if (shouldReplaceRealBadges()) return [];

    const profile = getProfile();
    const badges: ProfileBadge[] = [];
    let idx = 0;

    for (const badgeId of profile.selectedBadges) {
        const def = PROFILE_BADGES.find(b => b.id === badgeId);
        if (!def) continue;
        badges.push({
            id: `vc-cp-${def.id}-${idx++}`,
            description: def.description,
            iconSrc: badgeIcon(def.iconHash),
            position: BadgePosition.START,
        });
    }

    for (const specialId of profile.selectedSpecialBadges) {
        const def = SPECIAL_BADGES.find(b => b.id === specialId);
        if (!def) continue;
        badges.push({
            id: `vc-cp-${def.id}-${idx++}`,
            description: def.description,
            iconSrc: badgeIcon(def.iconHash),
            position: BadgePosition.END,
        });
    }

    const nitro = NITRO_TIERS.find(t => t.id === profile.nitroTier);
    if (nitro && nitro.id !== "none" && nitro.iconHash) {
        badges.push({
            id: `vc-cp-nitro-${idx++}`,
            description: nitro.description || "Discord Nitro",
            iconSrc: badgeIcon(nitro.iconHash),
            position: BadgePosition.END,
        });
    }

    const boost = BOOST_TIERS.find(t => t.id === profile.boostTier);
    if (boost && boost.id !== "none" && boost.iconHash) {
        badges.push({
            id: `vc-cp-boost-${idx++}`,
            description: `Server Booster (${boost.name})`,
            iconSrc: badgeIcon(boost.iconHash),
            position: BadgePosition.END,
        });
    }

    return badges;
}

export function patchUserProfile(profile: UserProfile | null | undefined): UserProfile | null | undefined {
    if (!profile?.userId || profile.userId !== getCurrentUserId()) return profile;
    if (!shouldReplaceRealBadges()) return profile;

    const data = getProfile();
    const nitro = NITRO_TIERS.find(t => t.id === data.nitroTier);
    const boost = BOOST_TIERS.find(t => t.id === data.boostTier);

    return virtualMerge(profile, {
        badges: buildNativeProfileBadges(data),
        premiumType: nitro && nitro.id !== "none" ? 2 : 0,
        premiumSince: nitro && nitro.id !== "none" ? new Date(monthsToPremiumSince(nitro.months)) : null,
        premiumGuildSince: boost && boost.id !== "none" ? new Date(monthsToPremiumSince(boost.months)) : null,
    });
}

export function applyProfileChanges() {
    const userId = getCurrentUserId();
    if (!userId) return;

    FluxDispatcher.dispatch({
        type: "USER_UPDATE",
        user: patchUser(UserStore.getCurrentUser()),
    });

    FluxDispatcher.dispatch({
        type: "CURRENT_USER_UPDATE",
        user: patchUser(UserStore.getCurrentUser()),
    });

    FluxDispatcher.dispatch({
        type: "USER_PROFILE_UPDATE",
        userId,
    });
}

export function patchUser<T extends User | null | undefined>(user: T): T {
    if (!user || !isSelf(user.id)) return user;

    return new Proxy(user, {
        get(target, prop, receiver) {
            const profile = getProfile();

            switch (prop) {
                case "publicFlags":
                    return getComputedPublicFlags();
                case "username": {
                    const custom = profile.customUsername.trim();
                    return custom || Reflect.get(target, prop, receiver);
                }
                case "globalName":
                case "global_name": {
                    const custom = profile.customDisplayName.trim() || profile.customUsername.trim();
                    return custom || Reflect.get(target, prop, receiver);
                }
                case "premiumType":
                    return getPremiumType();
                case "avatarDecoration":
                case "avatarDecorationData": {
                    const deco = getAvatarDecoration();
                    if (deco) return deco;
                    return Reflect.get(target, prop, receiver);
                }
                default:
                    return Reflect.get(target, prop, receiver);
            }
        },
    }) as T;
}

export function registerBadgeProvider() {
    if (badgeRegistration) return;

    badgeRegistration = {
        id: "vc-custom-profile-provider",
        getBadges({ userId }) {
            return buildBadgesForUser(userId);
        },
    };

    addProfileBadge(badgeRegistration);
}

export function unregisterBadgeProvider() {
    if (badgeRegistration) {
        removeProfileBadge(badgeRegistration);
        badgeRegistration = null;
    }
}

export function refreshBadges() {
    applyProfileChanges();
}

export function clearBadges() {
    unregisterBadgeProvider();
}

export function toggleBadgeSelection(selected: string[], badgeId: string, exclusiveGroup?: string): string[] {
    const badge = PROFILE_BADGES.find(b => b.id === badgeId);
    if (!badge) return selected;

    if (selected.includes(badgeId)) {
        return selected.filter(id => id !== badgeId);
    }

    let next = [...selected, badgeId];
    if (exclusiveGroup) {
        next = next.filter(id => {
            const other = PROFILE_BADGES.find(b => b.id === id);
            return !other || other.exclusiveGroup !== exclusiveGroup || id === badgeId;
        });
    }
    return next;
}
