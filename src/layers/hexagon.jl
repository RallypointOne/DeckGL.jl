"""
    HexagonLayer(; data, get_position, kwargs...)

Aggregates data into hexagonal bins and renders as 3D hexagons.

# Required Arguments
- `data`: Any Tables.jl-compatible data source
- `get_position`: Column accessor for [longitude, latitude]

# Optional Arguments
- `id::String`: Unique layer identifier
- `radius::Real`: Hexagon radius in meters. Default: `1000`
- `elevation_scale::Real`: Elevation multiplier for 3D effect. Default: `1`
- `elevation_range::Vector{<:Real}`: Min/max elevation `[min, max]`. Default: `[0, 1000]`
- `extruded::Bool`: Render as 3D hexagons. Default: `true`
- `coverage::Real`: Hexagon coverage (0-1). Default: `1`
- `get_color_weight::Union{Real,Symbol}`: Weight for color aggregation. Default: `1`
- `get_elevation_weight::Union{Real,Symbol}`: Weight for elevation aggregation. Default: `1`
- `color_aggregation::String`: Aggregation method ("SUM", "MEAN", "MIN", "MAX"). Default: `"SUM"`
- `elevation_aggregation::String`: Aggregation method. Default: `"SUM"`
- `color_range::Vector`: Array of RGB colors for color scale. Default: 6-color yellow-red scale
- `upper_percentile::Real`: Filter out bins above this percentile. Default: `100`
- `lower_percentile::Real`: Filter out bins below this percentile. Default: `0`
- `opacity::Real`: Layer opacity (0-1). Default: `1`
- `pickable::Bool`: Enable interactions. Default: `false`
- `visible::Bool`: Layer visibility. Default: `true`

# Example
```julia
earthquakes = (
    lng = rand(-180.0:0.01:180.0, 10000),
    lat = rand(-60.0:0.01:60.0, 10000),
    magnitude = rand(1.0:0.1:8.0, 10000)
)

layer = HexagonLayer(
    data = earthquakes,
    get_position = [:lng, :lat],
    get_elevation_weight = :magnitude,
    radius = 50000,
    elevation_scale = 100,
    extruded = true
)
```
"""
Base.@kwdef struct HexagonLayer <: AbstractLayer
    # Required
    data::Any
    get_position::Union{Symbol,Vector{Symbol}}

    # Identity
    id::String = "hexagon-" * string(uuid4())[1:8]

    # Hexagon geometry
    radius::Real = 1000
    coverage::Real = 1

    # 3D extrusion
    extruded::Bool = true
    elevation_scale::Real = 1
    elevation_range::Vector{<:Real} = [0, 1000]

    # Aggregation weights
    get_color_weight::Union{Real,Symbol} = 1
    get_elevation_weight::Union{Real,Symbol} = 1

    # Aggregation methods
    color_aggregation::String = "SUM"
    elevation_aggregation::String = "SUM"

    # Color scale (default: yellow to red)
    color_range::Vector = [
        [255, 255, 178],
        [254, 217, 118],
        [254, 178, 76],
        [253, 141, 60],
        [240, 59, 32],
        [189, 0, 38]
    ]

    # Filtering
    upper_percentile::Real = 100
    lower_percentile::Real = 0

    # Render
    opacity::Real = 1.0
    pickable::Bool = false
    visible::Bool = true
end
