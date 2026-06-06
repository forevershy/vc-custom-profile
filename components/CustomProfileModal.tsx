/*
 * CustomProfile - Settings modal
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { classNameFactory } from "@utils/css";
import { Margins } from "@utils/margins";
import { RenderModalProps } from "@vencord/discord-types";
import { Button, Forms, Modal, ScrollerThin, Select, Switch, TextInput, useMemo, useState } from "@webpack/common";

import {
    badgeIcon,
    BOOST_TIERS,
    NITRO_TIERS,
    PROFILE_BADGES,
    SPECIAL_BADGES,
    type BoostTier,
    type NitroTier,
} from "../badges";
import {
    DECORATION_COLLECTIONS,
    DECORATION_PRESETS,
    filterDecorations,
    getDecorationPreviewUrl,
    getDecorationPresetPreview,
} from "../decorations";
import { getProfile, resetProfile, setProfile, type CustomProfileData } from "../settings";
import { applyProfileChanges, toggleBadgeSelection } from "../utils";

const cl = classNameFactory("vc-custom-profile-");

interface DraftState extends CustomProfileData {
    customDecorationAsset: string;
}

function buildDraft(): DraftState {
    const profile = getProfile();
    const knownPreset = DECORATION_PRESETS.some(p => p.asset && p.asset === profile.avatarDecoration);
    return {
        ...profile,
        customDecorationAsset: knownPreset || !profile.avatarDecoration ? "" : profile.avatarDecoration,
    };
}

export function CustomProfileModal({ modalProps }: { modalProps: RenderModalProps; }) {
    const [draft, setDraft] = useState(buildDraft);
    const [decoSearch, setDecoSearch] = useState("");
    const [decoCollection, setDecoCollection] = useState("");

    const filteredDecorations = useMemo(
        () => filterDecorations(decoSearch, decoCollection),
        [decoSearch, decoCollection]
    );

    const collectionOptions = useMemo(() => [
        { label: "All collections", value: "" },
        ...DECORATION_COLLECTIONS.map(c => ({ label: c, value: c })),
    ], []);

    const update = (partial: Partial<DraftState>) => setDraft({ ...draft, ...partial });

    const save = () => {
        const decoration = draft.avatarDecoration || draft.customDecorationAsset.trim();
        setProfile({
            customUsername: draft.customUsername.trim(),
            customDisplayName: draft.customDisplayName.trim(),
            selectedBadges: draft.selectedBadges,
            selectedSpecialBadges: draft.selectedSpecialBadges,
            nitroTier: draft.nitroTier,
            boostTier: draft.boostTier,
            avatarDecoration: decoration,
            replaceRealBadges: draft.replaceRealBadges,
            customAccountCreationDate: draft.customAccountCreationDate.trim(),
        });
        applyProfileChanges();
        modalProps.onClose();
    };

    const onReset = () => {
        resetProfile();
        applyProfileChanges();
        setDraft(buildDraft());
    };

    return (
        <Modal
            {...modalProps}
            title="Custom Profile"
            size="medium"
            className={cl("modal")}
        >
            <div className={cl("input-row")}>
                <Forms.FormTitle tag="h5">Custom Username</Forms.FormTitle>
                <TextInput
                    value={draft.customUsername}
                    onChange={v => update({ customUsername: v })}
                    placeholder="Leave empty to keep your real username"
                />
            </div>

            <div className={cl("input-row")}>
                <Forms.FormTitle tag="h5">Custom Display Name</Forms.FormTitle>
                <TextInput
                    value={draft.customDisplayName}
                    onChange={v => update({ customDisplayName: v })}
                    placeholder="Leave empty to keep your real display name"
                />
            </div>

            <div className={cl("input-row")}>
                <Forms.FormTitle tag="h5">Account Creation Date</Forms.FormTitle>
                <input
                    type="date"
                    className={cl("date-input")}
                    value={draft.customAccountCreationDate}
                    onChange={e => update({ customAccountCreationDate: e.currentTarget.value })}
                />
                <span className={cl("date-hint")}>
                    Leave empty to keep your real account creation date. Only visible to you locally.
                </span>
            </div>

            <Switch
                note="When enabled, only your selected badges show (hides your real badges locally)."
                value={draft.replaceRealBadges}
                onChange={v => update({ replaceRealBadges: v })}
            >
                Replace real badges
            </Switch>

            <div className={`${cl("section")} ${Margins.top16}`}>
                <div className={cl("section-title")}>Badges</div>
                <div className={cl("grid")}>
                    {PROFILE_BADGES.map(badge => (
                        <div
                            key={badge.id}
                            className={`${cl("pill")}${draft.selectedBadges.includes(badge.id) ? " selected" : ""}`}
                            onClick={() => update({
                                selectedBadges: toggleBadgeSelection(draft.selectedBadges, badge.id, badge.exclusiveGroup),
                            })}
                            title={badge.description}
                        >
                            <img src={badgeIcon(badge.iconHash)} alt="" draggable={false} />
                            {badge.name}
                        </div>
                    ))}
                </div>
            </div>

            <div className={cl("section")}>
                <div className={cl("section-title")}>Evolving Nitro Badge</div>
                <div className={cl("tier-row")}>
                    {NITRO_TIERS.filter(t => t.id !== "none").map(tier => (
                        <div
                            key={tier.id}
                            className={`${cl("pill")} ${cl("tier")}${draft.nitroTier === tier.id ? " selected" : ""}`}
                            onClick={() => update({ nitroTier: tier.id as NitroTier })}
                            title={tier.description}
                        >
                            <img src={badgeIcon(tier.iconHash)} alt="" draggable={false} />
                            {tier.name}
                        </div>
                    ))}
                </div>
            </div>

            <div className={cl("section")}>
                <div className={cl("section-title")}>Special Badges</div>
                <div className={cl("grid")}>
                    {SPECIAL_BADGES.map(badge => (
                        <div
                            key={badge.id}
                            className={`${cl("pill")}${draft.selectedSpecialBadges.includes(badge.id) ? " selected" : ""}`}
                            onClick={() => {
                                const selected = draft.selectedSpecialBadges.includes(badge.id)
                                    ? draft.selectedSpecialBadges.filter(id => id !== badge.id)
                                    : [...draft.selectedSpecialBadges, badge.id];
                                update({ selectedSpecialBadges: selected });
                            }}
                        >
                            <img src={badgeIcon(badge.iconHash)} alt="" draggable={false} />
                            {badge.name}
                        </div>
                    ))}
                </div>
            </div>

            <div className={cl("section")}>
                <div className={cl("section-title")}>Boost Badge (Server Booster)</div>
                <div className={cl("tier-row")}>
                    {BOOST_TIERS.filter(t => t.id !== "none").map(tier => (
                        <div
                            key={tier.id}
                            className={`${cl("pill")} ${cl("tier")}${draft.boostTier === tier.id ? " selected" : ""}`}
                            onClick={() => update({ boostTier: tier.id as BoostTier })}
                        >
                            <img src={badgeIcon(tier.iconHash)} alt="" draggable={false} />
                            {tier.name}
                        </div>
                    ))}
                </div>
            </div>

            <div className={cl("section")}>
                <div className={cl("section-title")}>Avatar Decoration</div>
                <div className={cl("deco-filters")}>
                    <TextInput
                        value={decoSearch}
                        onChange={setDecoSearch}
                        placeholder="Search decorations..."
                    />
                    <Select
                        options={collectionOptions}
                        isSelected={v => v === decoCollection}
                        select={setDecoCollection}
                        serialize={v => v}
                    />
                </div>
                <div className={cl("deco-count")}>
                    {filteredDecorations.length} of {DECORATION_PRESETS.length - 1} decorations
                </div>
                <ScrollerThin className={cl("deco-scroll")}>
                    <div className={cl("deco-grid")}>
                        {DECORATION_PRESETS.filter(p => p.id === "none").map(preset => (
                            <div
                                key={preset.id}
                                className={`${cl("deco")}${(!draft.avatarDecoration && preset.id === "none") || draft.avatarDecoration === preset.asset ? " selected" : ""}`}
                                onClick={() => update({ avatarDecoration: preset.asset, customDecorationAsset: "" })}
                                title={preset.name}
                            >
                                <span className={cl("deco-none")}>None</span>
                            </div>
                        ))}
                        {filteredDecorations.map(preset => (
                            <div
                                key={preset.asset}
                                className={`${cl("deco")}${draft.avatarDecoration === preset.asset ? " selected" : ""}`}
                                onClick={() => update({ avatarDecoration: preset.asset, customDecorationAsset: "" })}
                                title={`${preset.name}${preset.collection ? ` (${preset.collection})` : ""}`}
                            >
                                <img src={getDecorationPresetPreview(preset)} alt={preset.name} draggable={false} />
                            </div>
                        ))}
                    </div>
                </ScrollerThin>
                <div className={`${cl("input-row")} ${Margins.top8}`}>
                    <Forms.FormTitle tag="h5">Custom Decoration Asset ID</Forms.FormTitle>
                    <TextInput
                        value={draft.customDecorationAsset}
                        onChange={v => update({ customDecorationAsset: v, avatarDecoration: v.trim() })}
                        placeholder="e.g. a_fed43ab12698df65902ba06727e20c0e"
                    />
                    {draft.customDecorationAsset.trim() && (
                        <img
                            src={getDecorationPreviewUrl(draft.customDecorationAsset.trim())}
                            alt="Preview"
                            width={64}
                            height={64}
                            draggable={false}
                        />
                    )}
                </div>
            </div>

            <p className={cl("note")}>
                All changes are client-side only — only you can see your custom profile.
                Open your profile or restart Discord if changes do not appear immediately.
            </p>

            <div className={cl("footer")}>
                <Button
                    color={Button.Colors.RED}
                    look={Button.Looks.FILLED}
                    onClick={onReset}
                >
                    Reset
                </Button>
                <Button
                    look={Button.Looks.LINK}
                    onClick={modalProps.onClose}
                >
                    Cancel
                </Button>
                <Button onClick={save}>
                    Save
                </Button>
            </div>
        </Modal>
    );
}
