module DeckGL

using JSON3
using Tables
using UUIDs: uuid4
using Base64: base64encode

# Core types
export Deck, ViewState, AbstractLayer

# Core layers
export ScatterplotLayer, ArcLayer, LineLayer, PathLayer, PolygonLayer, TextLayer

# Aggregation layers
export HexagonLayer, GridLayer, HeatmapLayer

# Composite layers
export GeoJsonLayer

# Functions
export to_json, to_html, save_html, open_html

# Convenience functions
export scatter, arcs, lines, paths, polygons, text
export hexbin, heatmap, geojson

# GeoInterface integration
export to_geojson, geojson_layer

# Include source files
include("types.jl")
include("layers/layers.jl")
include("json.jl")
include("render.jl")
include("display.jl")
include("convenience.jl")
include("geointerface.jl")

end # module
