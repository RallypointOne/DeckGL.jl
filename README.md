[![CI](https://github.com/RallypointOne/DeckGL.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/RallypointOne/DeckGL.jl/actions/workflows/CI.yml)
[![Docs Build](https://github.com/RallypointOne/DeckGL.jl/actions/workflows/Docs.yml/badge.svg)](https://github.com/RallypointOne/DeckGL.jl/actions/workflows/Docs.yml)
[![Stable Docs](https://img.shields.io/badge/docs-stable-blue)](https://RallypointOne.github.io/DeckGL.jl/stable/)
[![Dev Docs](https://img.shields.io/badge/docs-dev-blue)](https://RallypointOne.github.io/DeckGL.jl/dev/)

# DeckGL.jl

A Julia package for visualizing data using [deck.gl](https://deck.gl/), a WebGL-powered framework for visual exploratory data analysis of large datasets.

**[Documentation](https://RallypointOne.github.io/DeckGL.jl/stable/)**

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/RallypointOne/DeckGL.jl")
```

## Quick Start

```julia
using DeckGL

# Sample data (any Tables.jl-compatible source works)
data = (
    longitude = [-122.4, -122.5, -122.3, -122.45, -122.35],
    latitude = [37.8, 37.7, 37.9, 37.75, 37.85],
    size = [100, 200, 150, 180, 120]
)

# Create a scatterplot layer
layer = ScatterplotLayer(
    data = data,
    get_position = [:longitude, :latitude],
    get_radius = :size,
    get_fill_color = [255, 140, 0, 200]
)

# Create the deck, on a basemap
deck = Deck(
    layer,
    initial_view_state = ViewState(longitude=-122.4, latitude=37.8, zoom=11),
    map_style = "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json"
)

# Display in notebook or open in browser
open_html(deck)
```

`map_style` is the URL of a [MapLibre](https://maplibre.org/) style. Carto's are free and
need no API key — swap `positron` for `dark-matter` or `voyager`. Leave `map_style` out
and the layers are drawn on a blank background. A basemap is fetched at view time, so it
needs network access.

## Features

- **Tables.jl Integration**: Works with DataFrames, NamedTuples, and any Tables.jl-compatible source
- **Multiple Display Targets**: Jupyter notebooks, VS Code, standalone HTML files
- **GPU-Accelerated**: Leverages deck.gl's WebGL rendering for large datasets
- **Interactive**: Pan, zoom, and rotate visualizations

## API

### Core Types

- `Deck(layers; initial_view_state, map_style, controller)` - Top-level visualization container
- `ViewState(; longitude, latitude, zoom, pitch, bearing)` - Camera configuration

### Layers

All 32 deck.gl layers are available, generated from deck.gl's own prop tables. See the
[Layers page](https://rallypointone.github.io/DeckGL.jl/layers.html) for a live example
of each.

**Core** — one shape per record:
`ScatterplotLayer`, `ArcLayer`, `LineLayer`, `PathLayer`, `PolygonLayer`,
`SolidPolygonLayer`, `TextLayer`, `IconLayer`, `BitmapLayer`, `ColumnLayer`,
`GridCellLayer`, `PointCloudLayer`, `GeoJsonLayer`

**Aggregation** — bin records before drawing:
`HexagonLayer`, `GridLayer`, `HeatmapLayer`, `ContourLayer`, `ScreenGridLayer`

**Geo** — spatial indexes and tiled sources:
`GreatCircleLayer`, `TripsLayer`, `TileLayer`, `MVTLayer`, `TerrainLayer`,
`Tile3DLayer`, `H3HexagonLayer`, `H3ClusterLayer`, `GeohashLayer`, `QuadkeyLayer`,
`S2Layer`, `A5Layer`

**Mesh** — 3D geometry per record:
`SimpleMeshLayer`, `ScenegraphLayer`

Props may be written `snake_case` or `camelCase`, and anything left unset keeps
deck.gl's own default. `DeckGL.props(ScatterplotLayer)` lists what a layer accepts and
`DeckGL.accessors(ScatterplotLayer)` lists the props that can name a data column.

### Widgets

All 15 deck.gl widgets are available. See the
[Widgets page](https://rallypointone.github.io/DeckGL.jl/widgets.html) for a live example
of each.

**Camera** — `ZoomWidget`, `CompassWidget`, `GimbalWidget`, `ResetViewWidget`,
`ScrollbarWidget`

**Display** — `FullscreenWidget`, `ThemeWidget`, `ScreenshotWidget`, `LoadingWidget`

**Information** — `InfoWidget`, `PopupWidget`, `ContextMenuWidget`

**Custom controls** — `IconWidget`, `ToggleWidget`, `SelectorWidget`

```julia
Deck(layer, widgets = [ZoomWidget(), CompassWidget(placement = "bottom-left")])
```

### Functions

- `to_js(deck)` - The JavaScript that builds and mounts the visualization
- `to_html(deck)` - Generate an HTML page (`bundle=:local` inlines deck.gl for offline use)
- `save_html(deck, path)` - Save as HTML file
- `open_html(deck)` - Open in default browser

### Convenience Functions

Quick visualization helpers that return a `Deck` ready to display:

```julia
scatter(data, :lng, :lat; radius=:size, color=[255, 140, 0])
arcs(data, [:src_lng, :src_lat], [:dst_lng, :dst_lat])
lines(data, [:from_lng, :from_lat], [:to_lng, :to_lat])
paths(data, :path_column)
polygons(data, :polygon_column)
text(data, :lng, :lat, :label_column)
hexbin(data, :lng, :lat; radius=1000)  # 3D hexagonal binning
heatmap(data, :lng, :lat; weight=:value)  # Density heatmap
geojson(geojson_data)  # GeoJSON visualization
```

## License

MIT
