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

# Create the deck
deck = Deck(
    layer,
    initial_view_state = ViewState(longitude=-122.4, latitude=37.8, zoom=11)
)

# Display in notebook or open in browser
open_html(deck)
```

## Features

- **Tables.jl Integration**: Works with DataFrames, NamedTuples, and any Tables.jl-compatible source
- **Multiple Display Targets**: Jupyter notebooks, VS Code, standalone HTML files
- **GPU-Accelerated**: Leverages deck.gl's WebGL rendering for large datasets
- **Interactive**: Pan, zoom, and rotate visualizations

## API

### Core Types

- `Deck(layers; initial_view_state, map_style, controller)` - Top-level visualization container
- `ViewState(; longitude, latitude, zoom, pitch, bearing)` - Camera configuration

### Core Layers

- `ScatterplotLayer` - Render points/circles at coordinates
- `ArcLayer` - Render arcs between source and target points
- `LineLayer` - Render straight lines between points
- `PathLayer` - Render paths/polylines from coordinate sequences
- `PolygonLayer` - Render filled/stroked polygons
- `TextLayer` - Render text labels at coordinates

### Aggregation Layers

- `HexagonLayer` - Aggregate points into hexagonal bins (3D)
- `GridLayer` - Aggregate points into rectangular grid cells (3D)
- `HeatmapLayer` - Render density heatmaps

### Composite Layers

- `GeoJsonLayer` - Render GeoJSON data (points, lines, polygons)

### Functions

- `to_json(deck)` - Convert to deck.gl JSON specification
- `to_html(deck)` - Generate standalone HTML string
- `save_html(deck, path)` - Save as HTML file
- `open_html(deck)` - Open in default browser

### GeoInterface.jl Integration

Convert GeoInterface-compatible geometries to GeoJSON:

```julia
using Shapefile
shp = Shapefile.Table("boundaries.shp")
layer = geojson_layer(shp, get_fill_color=[255, 0, 0, 100])
```

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
