# Code generation

`src/metadata.jl` and the `deckgl` artifact binding in `Artifacts.toml` are generated
from a deck.gl release. Nothing in either file is hand-maintained.

deck.gl publishes no schema, but every layer, widget, and view class carries a static
`defaultProps` table naming its props and marking the data accessors. Reading that table
out of the shipped bundle keeps the Julia bindings in step with the exact version the
package renders against, and means a version bump is one command rather than 32 files of
transcribed prop tables.

## Running it

Requires `node` on `PATH` and network access.

```
julia --project=gen gen/generate.jl 9.3.11
```

The version argument is the deck.gl release to target; it defaults to the currently
pinned one. The script:

1. Downloads `deck.gl-<version>.tgz` from the npm registry.
2. Binds it as a **lazy** artifact named `deckgl` in `Artifacts.toml`, so users only
   download it if they ask for `bundle=:local`.
3. Runs `gen/introspect.js` against the unpacked `dist.min.js`, writing
   `gen/deckgl-meta.json`.
4. Writes `src/metadata.jl` from that JSON.

## Files

| File | Role |
|------|------|
| `generate.jl` | Driver: artifact binding and `src/metadata.jl` emission |
| `introspect.js` | Loads the UMD bundle in a `node` VM and extracts the prop tables |
| `deckgl-meta.json` | Intermediate output, committed so the diff of a version bump is reviewable |
| `Project.toml` | Environment for `generate.jl` (JSON plus stdlibs) |

`introspect.js` stubs a minimal browser (`window`, `document`, `navigator`) — enough to
reach the class definitions. Nothing is rendered.

## What gets derived, and how

- **`LAYER_PROPS` / `WIDGET_PROPS` / `VIEW_PROPS`** — every prop the class accepts.
  Used to warn on typos, never to reject: a prop unknown to this version of the bindings
  may be valid in a newer deck.gl.

- **`LAYER_ACCESSORS`** — the props marked `type: 'accessor'`, which is exactly the set
  that may name a data column. This replaces guessing from the value's Julia type.

- **`COLOR_PROPS`** — which props hold a color, **per class**. This cannot be decided
  from the prop's name: `color` is RGB(A) on `TerrainLayer` and a CSS string on
  `IconWidget`, and `getColorWeight` is a number despite how it reads. A prop counts as a
  color when deck.gl types it `color`, when it is an accessor whose default is a 3- or
  4-element numeric array, or when its default is a list of such arrays (which is how
  `colorRange` is picked up, without naming it).

- **`AGGREGATION_LAYERS`** — the layers from deck.gl's `aggregation-layers` submodule.
  This drives a real behavioral fork: those layers bin their records before drawing and
  read each one through its accessor, so they silently ignore binary attributes (a
  `HexagonLayer` given them produces a single bin). `resolve_data` sends them an index
  array instead. Derived from the submodule rather than a hand-kept list.

- **`LAYER_DOCS`** — the deck.gl API reference URL. The owning submodule comes from
  `dist/index.d.ts`, which re-exports each class from `@deck.gl/layers`,
  `@deck.gl/geo-layers`, and so on; the slug is the class name in kebab case.

## Things that surprised us

Worth knowing before changing `introspect.js`:

- **`defaultProps` is not merged along the prototype chain.** deck.gl merges at
  construction time, so a subclass's table holds only its own props —
  `ScatterplotLayer.defaultProps` has 21 entries while `Layer.defaultProps` has 32.
  `mergedProps` walks the chain.

- **`View` classes have no `defaultProps` at all**, so their prop tables come out empty.
  `check_props` treats an empty table as "no information" and skips validation, rather
  than warning on every prop.

- **Two doc slugs do not kebab-case correctly** (`GeoJsonLayer` → `geojson-layer`,
  `Tile3DLayer` → `tile-3d-layer`). `SLUG_OVERRIDES` covers them.

- **Props with a `deprecatedFor` entry are dropped**, so deprecated spellings do not
  appear as valid.

## Not derived

Two things in `src/` are deliberately hand-maintained, because no metadata source exists:

- **`PEER_SCRIPTS`** (`src/render.jl`) — deck.gl bundles its dependencies with one
  exception: the shipped `dist.min.js` reads `globalThis.h3`, so a page drawing H3 cells
  must load h3-js itself. Everything else `@deck.gl/geo-layers` depends on, a5-js
  included, is compiled in. To check this on a version bump:
  `grep -o "globalThis\.[a-zA-Z0-9_]* *||" dist.min.js`. The pinned h3-js version should
  track the range `@deck.gl/geo-layers` declares.

- **The MapLibre pin** (`CDN_MAPLIBRE_JS` / `CDN_MAPLIBRE_CSS`) — a separate project with
  no relationship to the deck.gl release.

## After a version bump

`src/metadata.jl` is the only generated Julia file, but a bump can change behavior
elsewhere. Worth running:

```
julia --project -e 'using Pkg; Pkg.test()'
```

The suite checks that every generated layer and widget name still has a documentation
section, so newly added classes fail loudly instead of going undocumented.

Then the browser check, which is what catches a layer that constructs cleanly but no
longer draws:

```
npm install puppeteer            # anywhere; not a repo dependency
NODE_PATH=<path>/node_modules DECKGL_BROWSER_TESTS=1 julia --project -e 'using Pkg; Pkg.test()'
```

Finally, re-render the docs — the per-layer prop tables and the H3/A5/geohash examples
are generated from this metadata:

```
quarto render docs
```
