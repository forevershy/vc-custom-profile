/**
 * Local CustomProfile registry (same API as worker.js).
 * Stores profiles in ./data/{userId}.json
 */
import { createServer } from "node:http";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";

const PORT = Number(process.env.PORT || 8787);
const DATA_DIR = join(import.meta.dirname, "data");

const CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, PUT, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
};

function sendJson(res, body, status = 200) {
    res.writeHead(status, { ...CORS, "Content-Type": "application/json" });
    res.end(JSON.stringify(body));
}

function readBody(req) {
    return new Promise((resolve, reject) => {
        const chunks = [];
        req.on("data", chunk => chunks.push(chunk));
        req.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
        req.on("error", reject);
    });
}

await mkdir(DATA_DIR, { recursive: true });

createServer(async (req, res) => {
    try {
        if (req.method === "OPTIONS") {
            res.writeHead(204, CORS);
            res.end();
            return;
        }

        const url = new URL(req.url ?? "/", `http://127.0.0.1:${PORT}`);
        const match = url.pathname.match(/^\/profile\/(\d{17,20})$/);
        if (!match) {
            sendJson(res, { error: "not found" }, 404);
            return;
        }

        const userId = match[1];
        const filePath = join(DATA_DIR, `${userId}.json`);

        if (req.method === "GET") {
            try {
                const raw = await readFile(filePath, "utf8");
                res.writeHead(200, { ...CORS, "Content-Type": "application/json" });
                res.end(raw);
            } catch {
                sendJson(res, { error: "not found" }, 404);
            }
            return;
        }

        if (req.method === "PUT") {
            const body = await readBody(req);
            try {
                const parsed = JSON.parse(body);
                if (parsed.userId !== userId) {
                    sendJson(res, { error: "userId mismatch" }, 400);
                    return;
                }
            } catch {
                sendJson(res, { error: "invalid json" }, 400);
                return;
            }

            await writeFile(filePath, body, "utf8");
            sendJson(res, { ok: true });
            return;
        }

        sendJson(res, { error: "method not allowed" }, 405);
    } catch (err) {
        console.error(err);
        res.writeHead(500, { "Content-Type": "text/plain" });
        res.end("internal error");
    }
}).listen(PORT, "127.0.0.1", () => {
    console.log(`CustomProfile registry listening on http://127.0.0.1:${PORT}`);
});
