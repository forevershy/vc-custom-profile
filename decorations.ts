/*
 * CustomProfile - Avatar decoration presets
 * Asset IDs from Discord's avatar decoration presets CDN.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import decorationsData from "./decorations.json";

export interface DecorationPreset {
    id: string;
    name: string;
    asset: string;
    collection: string;
}

const DECOR_CDN = "https://cdn.discordapp.com/avatar-decoration-presets";

/** All known Discord avatar decoration presets (130+ from shop archive) */
export const DECORATION_PRESETS: DecorationPreset[] = decorationsData as DecorationPreset[];

export const DECORATION_COLLECTIONS = [...new Set(
    DECORATION_PRESETS.map(p => p.collection).filter(Boolean)
)].sort();

/** Fallback SKU id used for client-side decoration injection */
export const CUSTOM_DECORATION_SKU = "1144058844004233369";

export function getDecorationPreviewUrl(asset: string): string {
    if (!asset) return "";
    return `${DECOR_CDN}/${asset}.png?size=80&passthrough=false`;
}

export function getDecorationPresetPreview(preset: DecorationPreset): string {
    return getDecorationPreviewUrl(preset.asset);
}

export function filterDecorations(
    query: string,
    collection: string
): DecorationPreset[] {
    const q = query.trim().toLowerCase();
    return DECORATION_PRESETS.filter(preset => {
        if (preset.id === "none") return false;
        if (collection && preset.collection !== collection) return false;
        if (!q) return true;
        return preset.name.toLowerCase().includes(q)
            || preset.collection.toLowerCase().includes(q)
            || preset.asset.toLowerCase().includes(q);
    });
}
