/*
 * CustomProfile - Plugin settings
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { definePluginSettings } from "@api/Settings";
import { openModal } from "@utils/modal";
import { OptionType } from "@utils/types";
import { Button } from "@webpack/common";

import { CustomProfileModal } from "./components/CustomProfileModal";
import type { BoostTier, NitroTier } from "./badges";

export interface CustomProfileData {
    customUsername: string;
    customDisplayName: string;
    selectedBadges: string[];
    selectedSpecialBadges: string[];
    nitroTier: NitroTier;
    boostTier: BoostTier;
    avatarDecoration: string;
    replaceRealBadges: boolean;
    /** YYYY-MM-DD, empty = use real account creation date */
    customAccountCreationDate: string;
}

export const DEFAULT_PROFILE: CustomProfileData = {
    customUsername: "",
    customDisplayName: "",
    selectedBadges: [],
    selectedSpecialBadges: [],
    nitroTier: "none",
    boostTier: "none",
    avatarDecoration: "",
    replaceRealBadges: false,
    customAccountCreationDate: "",
};

export const settings = definePluginSettings({
    profileJson: {
        type: OptionType.STRING,
        description: "Internal profile data storage",
        default: JSON.stringify(DEFAULT_PROFILE),
        hidden: true,
    },
    openEditor: {
        type: OptionType.COMPONENT,
        component: () => (
            <Button onClick={() => openModal(props => <CustomProfileModal modalProps={props} />)}>
                Open Custom Profile Editor
            </Button>
        ),
    },
});

export function getProfile(): CustomProfileData {
    try {
        return { ...DEFAULT_PROFILE, ...JSON.parse(settings.store.profileJson) };
    } catch {
        return { ...DEFAULT_PROFILE };
    }
}

export function setProfile(data: Partial<CustomProfileData>) {
    settings.store.profileJson = JSON.stringify({ ...getProfile(), ...data });
}

export function resetProfile() {
    settings.store.profileJson = JSON.stringify(DEFAULT_PROFILE);
}

export function openEditor() {
    openModal(props => <CustomProfileModal modalProps={props} />);
}
