"""
    HeatmapLayer(; data, get_position, kwargs...)

Renders a heatmap based on point density and weights.

# Required Arguments
- `data`: Any Tables.jl-compatible data source
- `get_position`: Column accessor for [longitude, latitude]

# Optional Arguments
- `id::String`: Unique layer identifier
- `radius_pixels::Real`: Radius of influence in pixels. Default: `30`
- `intensity::Real`: Intensity multiplier. Default: `1`
- `threshold::Real`: Minimum density threshold (0-1). Default: `0.05`
- `get_weight::Union{Real,Symbol}`: Point weight for aggregation. Default: `1`
- `color_range::Vector`: Array of RGBA colors for heatmap gradient. Default: blue-green-yellow-red
- `aggregation::String`: Aggregation method ("SUM" or "MEAN"). Default: `"SUM"`
- `weights_texture_size::Int`: Resolution of weight texture. Default: `2048`
- `debounce_timeout::Int`: Debounce timeout in ms. Default: `500`
- `opacity::Real`: Layer opacity (0-1). Default: `1`
- `pickable::Bool`: Enable interactions. Default: `false`
- `visible::Bool`: Layer visibility. Default: `true`

# Example
```julia
incidents = (
    lng = rand(-122.5:-122.3, 10000),
    lat = rand(37.7:37.9, 10000),
    severity = rand(1:5, 10000)
)

layer = HeatmapLayer(
    data = incidents,
    get_position = [:lng, :lat],
    get_weight = :severity,
    radius_pixels = 50,
    intensity = 1,
    threshold = 0.03
)
```
"""
Base.@kwdef struct HeatmapLayer <: AbstractLayer
    # Required
    data::Any
    get_position::Union{Symbol,Vector{Symbol}}

    # Identity
    id::String = "heatmap-" * string(uuid4())[1:8]

    # Heatmap parameters
    radius_pixels::Real = 30
    intensity::Real = 1
    threshold::Real = 0.05
    get_weight::Union{Real,Symbol} = 1

    # Color gradient (default: transparent -> blue -> green -> yellow -> red)
    color_range::Vector{<:AbstractVector{<:Integer}} = [
        [0, 0, 255, 0],
        [0, 0, 255, 255],
        [0, 255, 0, 255],
        [255, 255, 0, 255],
        [255, 0, 0, 255]
    ]

    # Aggregation
    aggregation::String = "SUM"
    weights_texture_size::Int = 2048
    debounce_timeout::Int = 500

    # Render
    opacity::Real = 1.0
    pickable::Bool = false
    visible::Bool = true
end
