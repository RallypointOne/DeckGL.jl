// Render generated pages in headless Chrome and report whether deck.gl actually drew.
//
//   node test/browser/verify.js page.html [page.html ...]
//
// Asserting on the emitted JavaScript only proves it is the JavaScript we meant to
// emit. This proves the page runs: no console or page errors, deck.gl builds every
// layer, and picking finds geometry -- which it can only do once the layers have been
// rasterized on the GPU.
//
// Requires puppeteer, which is not a dependency of the package. Install it wherever is
// convenient and point NODE_PATH at it.

const path = require("path");
const puppeteer = require("puppeteer");

const RENDER_TIMEOUT_MS = 60000;
const SETTLE_MS = 3000;

async function verify(browser, file) {
    const page = await browser.newPage();
    const errors = [];
    page.on("console", m => m.type() === "error" && errors.push(m.text()));
    page.on("pageerror", e => errors.push(String(e)));
    await page.setViewport({width: 800, height: 600});

    try {
        await page.goto("file://" + path.resolve(file), {waitUntil: "load", timeout: RENDER_TIMEOUT_MS});
        await new Promise(r => setTimeout(r, SETTLE_MS));

        const result = await page.evaluate(async () => {
            // `DG` is a top-level `const`, a lexical binding rather than a property
            // of `window`, so it has to be reached by name.
            const instance = typeof DG === "undefined" ? null : DG.instance;
            if (!instance) return {mounted: false};
            // Picking reads the buffer deck.gl renders layer geometry into, so a hit
            // means the layers reached the GPU rather than merely being constructed.
            const picked = instance.pickObjects({x: 0, y: 0, width: 800, height: 600});
            // Exercise the tooltip the way deck.gl does, on a real picking result.
            const hit = instance.pickObject({x: 400, y: 300, radius: 250});
            const tooltip = hit && instance.props.getTooltip ? instance.props.getTooltip(hit) : null;

            return {
                mounted: true,
                layers: instance.props.layers.length,
                built: instance.layerManager ? instance.layerManager.getLayers().length : null,
                picked: picked.length,
                tooltip: tooltip && tooltip.html ? tooltip.html.slice(0, 120) : null,
            };
        });

        // Drive the camera the way a user would. deck.gl's controller is easy to break
        // from the outside -- an overlay above the canvas, or a second deck instance --
        // and neither rendering nor picking notices, because neither goes through the
        // event manager.
        const before = await page.evaluate(() => JSON.stringify(DG.instance.viewState));
        await page.mouse.move(400, 300);
        await page.mouse.wheel({deltaY: -500});
        await new Promise(r => setTimeout(r, 700));
        await page.mouse.move(400, 300);
        await page.mouse.down();
        await page.mouse.move(520, 370, {steps: 12});
        await page.mouse.up();
        await new Promise(r => setTimeout(r, 700));
        const interactive = before !== await page.evaluate(() => JSON.stringify(DG.instance.viewState));

        // Nothing above the canvas should be intercepting those events.
        const strays = await page.evaluate(() =>
            [...document.body.children].filter(e => e.id !== "deck-container" && e.tagName !== "SCRIPT").length);

        // Screenshot the page and count colors, which says whether anything was drawn
        // and in what color. Decoding happens in the page: a 2D canvas can be read back
        // where the WebGL drawing buffer cannot.
        const shot = await page.screenshot({encoding: "base64"});
        const colors = await page.evaluate(async b64 => {
            const img = new Image();
            await new Promise((ok, fail) => { img.onload = ok; img.onerror = fail; img.src = "data:image/png;base64," + b64; });
            const canvas = document.createElement("canvas");
            canvas.width = img.width;
            canvas.height = img.height;
            const ctx = canvas.getContext("2d");
            ctx.drawImage(img, 0, 0);
            const px = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
            const counts = new Map();
            for (let i = 0; i < px.length; i += 4) {
                const key = `${px[i]},${px[i + 1]},${px[i + 2]}`;
                counts.set(key, (counts.get(key) || 0) + 1);
            }
            return [...counts.entries()].sort((a, b) => b[1] - a[1]).slice(0, 4);
        }, shot);

        return {file, errors, colors, interactive, strays, ...result};
    } catch (e) {
        return {file, errors: errors.concat([String(e)]), mounted: false};
    } finally {
        await page.close();
    }
}

(async () => {
    const files = process.argv.slice(2);
    const browser = await puppeteer.launch({
        args: ["--enable-unsafe-swiftshader", "--use-gl=angle", "--use-angle=swiftshader", "--no-sandbox"],
    });

    let failed = 0;
    const report = [];
    for (const file of files) {
        const r = await verify(browser, file);
        // Some layers render through a framebuffer and expose no pickable geometry.
        const needsPick = !file.endsWith(".nopick.html");
        const drew = (r.colors || []).length > 1;   // background alone is not a render
        const ok = r.mounted && r.errors.length === 0 && drew && r.interactive && !r.strays
            && (!needsPick || r.picked > 0);
        if (!ok) failed++;
        report.push(r);
        const name = path.basename(file).padEnd(24);
        const top = (r.colors || []).map(([c, n]) => `${c}`).join(" | ");
        console.log(`${ok ? "pass" : "FAIL"}  ${name} layers=${r.layers ?? "-"} picked=${String(r.picked ?? "-").padEnd(4)} ` +
                    `${r.interactive ? "interactive" : "NOT-INTERACTIVE"}${r.strays ? ` strays=${r.strays}` : ""} colors=[${top}]`);
        if (r.tooltip) console.log(`        tooltip: ${r.tooltip.replace(/<[^>]*>/g, " ").trim()}`);
        for (const e of r.errors) console.log(`        ${e.split("\n")[0].slice(0, 200)}`);
    }
    await browser.close();
    console.log(JSON.stringify(report));
    process.exit(failed === 0 ? 0 : 1);
})();
