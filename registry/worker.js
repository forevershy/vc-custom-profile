/**
 * CustomProfile registry — Cloudflare Worker
 *
 * Deploy:
 *   1. Create a KV namespace named PROFILES in Cloudflare dashboard
 *   2. wrangler.toml:
 *        name = "customprofile-registry"
 *        main = "worker.js"
 *        [[kv_namespaces]]
 *        binding = "PROFILES"
 *        id = "<your-kv-namespace-id>"
 *   3. npx wrangler deploy
 *   4. Paste your worker URL into CustomProfile → Registry URL (no trailing slash)
 *
 * Routes:
 *   GET  /profile/:discordUserId  — fetch shared profile JSON
 *   PUT  /profile/:discordUserId  — publish shared profile JSON
 */

const CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, PUT, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
};

function json(body, status = 200) {
    return new Response(JSON.stringify(body), {
        status,
        headers: { ...CORS, "Content-Type": "application/json" },
    });
}

export default {
    async fetch(request, env) {
        if (request.method === "OPTIONS") {
            return new Response(null, { headers: CORS });
        }

        const url = new URL(request.url);
        const match = url.pathname.match(/^\/profile\/(\d{17,20})$/);
        if (!match) return json({ error: "not found" }, 404);

        const userId = match[1];

        if (request.method === "GET") {
            const raw = await env.PROFILES.get(userId);
            if (!raw) return json({ error: "not found" }, 404);
            return new Response(raw, {
                headers: { ...CORS, "Content-Type": "application/json" },
            });
        }

        if (request.method === "PUT") {
            const body = await request.text();
            try {
                const parsed = JSON.parse(body);
                if (parsed.userId !== userId) {
                    return json({ error: "userId mismatch" }, 400);
                }
            } catch {
                return json({ error: "invalid json" }, 400);
            }

            await env.PROFILES.put(userId, body);
            return json({ ok: true });
        }

        return json({ error: "method not allowed" }, 405);
    },
};
