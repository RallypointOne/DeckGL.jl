// Extract layer/widget/view metadata from the deck.gl UMD bundle.
//
// deck.gl publishes no schema, but every layer class carries a static
// `defaultProps` table naming each prop and marking the data accessors. Reading
// it from the shipped bundle keeps the Julia bindings in lockstep with the exact
// version we render against.
//
//   node gen/introspect.js <path-to-dist.min.js> <version> <output.json>

const fs = require("fs");
const vm = require("vm");

const [bundlePath, version, outPath] = process.argv.slice(2);
const pkgDir = require("path").dirname(bundlePath);

// The bundle is a UMD build expecting a browser. A minimal stub context is
// enough to reach the class definitions; nothing here is ever rendered.
const ctx = {
    console, setTimeout, clearTimeout, setInterval, clearInterval,
    TextDecoder, TextEncoder, URL, performance, process,
    fetch: () => {}, Blob: class {}, Worker: class {},
    navigator: {userAgent: "node"},
    document: {
        createElement: () => ({style: {}, getContext: () => null, appendChild() {}, setAttribute() {}}),
        head: {appendChild() {}}, body: {appendChild() {}},
        addEventListener() {}, documentElement: {style: {}},
    },
};
ctx.window = ctx;
ctx.self = ctx;
ctx.globalThis = ctx;
vm.createContext(ctx);
vm.runInContext(fs.readFileSync(bundlePath, "utf8"), ctx);

const deck = ctx.deck;
if (!deck) throw new Error("bundle did not define `deck`");

// deck.gl merges defaultProps along the prototype chain at construction time,
// not on the class, so a subclass table holds only its own props.
const isRGBA = v => Array.isArray(v) && v.length >= 3 && v.length <= 4 && v.every(Number.isFinite);

// Which props hold a color has to come from deck.gl rather than from the prop's name.
// `color` is RGB(A) on TerrainLayer and a CSS string on IconWidget, and `getColorWeight`
// is a number despite the name, so the answer is per class.
function isColorProp(described, value) {
    if (described.type === "color") return true;
    if (described.type === "accessor" && isRGBA(value)) return true;
    // A list of colors, e.g. `colorRange`.
    return Array.isArray(value) && value.length > 0 && value.every(isRGBA);
}

function mergedProps(Class) {
    const chain = [];
    for (let K = Class; K && K !== Object; K = Object.getPrototypeOf(K)) {
        if (Object.prototype.hasOwnProperty.call(K, "defaultProps")) chain.unshift(K.defaultProps);
    }
    const out = {};
    for (const table of chain) {
        for (const [name, spec] of Object.entries(table)) {
            const described = spec && typeof spec === "object" && !Array.isArray(spec) ? spec : {};
            if ("deprecatedFor" in described) { out[name] = {deprecated: true}; continue; }
            const value = "value" in described ? described.value : spec;
            out[name] = {type: described.type || "value", color: isColorProp(described, value)};
        }
    }
    return out;
}

function classify(suffix, skip) {
    const names = Object.keys(deck)
        .filter(k => k.endsWith(suffix) && !k.startsWith("_") && !skip.includes(k))
        .filter(k => typeof deck[k] === "function")
        .sort();
    return names;
}

// `index.d.ts` re-exports each class from its owning submodule, which is also the
// section it lives under in the deck.gl API reference.
const moduleOf = {};
for (const line of fs.readFileSync(`${pkgDir}/dist/index.d.ts`, "utf8").split("\n")) {
    const m = line.match(/^export \{([^}]*)\} from '@deck\.gl\/([a-z0-9-]+)'/);
    if (!m) continue;
    for (const sym of m[1].split(",")) moduleOf[sym.trim()] = m[2];
}
// Two class names do not kebab-case to their documented slug.
const SLUG_OVERRIDES = {GeoJsonLayer: "geojson-layer", Tile3DLayer: "tile-3d-layer"};
const kebab = n => SLUG_OVERRIDES[n] ||
    n.replace(/([a-z0-9])([A-Z])/g, "$1-$2").replace(/([A-Z]+)([A-Z][a-z])/g, "$1-$2").toLowerCase();

const layers = {};
for (const name of classify("Layer", ["Layer", "CompositeLayer"])) {
    const Class = deck[name];
    if (!(Class.prototype instanceof deck.Layer)) continue;
    const props = mergedProps(Class);
    const live = Object.entries(props).filter(([, v]) => !v.deprecated);
    const mod = moduleOf[name];
    layers[name] = {
        composite: Class.prototype instanceof deck.CompositeLayer,
        module: mod || "",
        docs: mod ? `https://deck.gl/docs/api-reference/${mod}/${kebab(name)}` : "https://deck.gl/docs/api-reference",
        props: live.map(([k]) => k).sort(),
        accessors: live.filter(([, v]) => v.type === "accessor").map(([k]) => k).sort(),
        colors: live.filter(([, v]) => v.color).map(([k]) => k).sort(),
        deprecated: Object.keys(props).filter(k => props[k].deprecated).sort(),
    };
}

function describe(name) {
    const props = mergedProps(deck[name]);
    const live = Object.entries(props).filter(([, v]) => !v.deprecated);
    return {
        props: live.map(([k]) => k).sort(),
        colors: live.filter(([, v]) => v.color).map(([k]) => k).sort(),
    };
}

const widgets = {};
for (const name of classify("Widget", ["Widget"])) widgets[name] = describe(name);

const views = {};
for (const name of classify("View", ["View"])) views[name] = describe(name);

fs.writeFileSync(outPath, JSON.stringify({version, layers, widgets, views}, null, 1));
console.error(`${Object.keys(layers).length} layers, ${Object.keys(widgets).length} widgets, ${Object.keys(views).length} views -> ${outPath}`);
