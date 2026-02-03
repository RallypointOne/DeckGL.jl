"""
    LineLayer(; data, get_source_position, get_target_position, kwargs...)

Renders straight lines between source and target coordinates.

# Required Arguments
- `data`: Any Tables.jl-compatible data source
- `get_source_position`: Column accessor for source [longitude, latitude]
- `get_target_position`: Column accessor for target [longitude, latitude]

# Optional Arguments
- `id::String`: Unique layer identifier
- `get_color`: Line color as `[R,G,B,A]` or column reference. Default: `[0,0,0,255]`
- `get_width::Union{Real,Symbol}`: Line width in pixels. Default: `1`
- `width_units::String`: Width units ("pixels" or "meters"). Default: `"pixels"`
- `width_scale::Real`: Width multiplier. Default: `1`
- `width_min_pixels::Real`: Minimum width. Default: `0`
- `width_max_pixels::Real`: Maximum width. Default: `Inf`
- `opacity::Real`: Layer opacity (0-1). Default: `1`
- `pickable::Bool`: Enable interactions. Default: `false`
- `visible::Bool`: Layer visibility. Default: `true`

# Example
```julia
connections = (
    from_lng = [-122.4, -122.5],
    from_lat = [37.8, 37.7],
    to_lng = [-122.3, -122.4],
    to_lat = [37.9, 37.8]
)

layer = LineLayer(
    data = connections,
    get_source_position = [:from_lng, :from_lat],
    get_target_position = [:to_lng, :to_lat],
    get_color = [255, 0, 0, 200],
    get_width = 2
)
```
"""
Base.@kwdef struct LineLayer <: AbstractLayer
    # Required
    data::Any
    get_source_position::Union{Symbol,Vector{Symbol}}
    get_target_position::Union{Symbol,Vector{Symbol}}

    # Identity
    id::String = "line-" * string(uuid4())[1:8]

    # Color
    get_color::Union{Vector{<:Integer},Symbol} = [0, 0, 0, 255]

    # Width
    get_width::Union{Real,Symbol} = 1
    width_units::String = "pixels"
    width_scale::Real = 1
    width_min_pixels::Real = 0
    width_max_pixels::Real = Inf

    # Render
    opacity::Real = 1.0
    pickable::Bool = false
    visible::Bool = true
end
