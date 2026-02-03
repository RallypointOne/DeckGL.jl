"""
    ArcLayer(; data, get_source_position, get_target_position, kwargs...)

Renders arcs between source and target coordinates.

# Required Arguments
- `data`: Any Tables.jl-compatible data source
- `get_source_position`: Column accessor for source [longitude, latitude].
  Can be a `Symbol` or `Vector{Symbol}` like `[:src_lng, :src_lat]`
- `get_target_position`: Column accessor for target [longitude, latitude].
  Can be a `Symbol` or `Vector{Symbol}` like `[:dst_lng, :dst_lat]`

# Optional Arguments
- `id::String`: Unique layer identifier
- `get_source_color`: Source end color as `[R,G,B,A]` or column reference
- `get_target_color`: Target end color as `[R,G,B,A]` or column reference
- `get_width::Union{Real,Symbol}`: Arc width in pixels. Default: `1`
- `get_height::Union{Real,Symbol}`: Arc height multiplier (0-1). Default: `1`
- `get_tilt::Union{Real,Symbol}`: Arc tilt in degrees. Default: `0`
- `great_circle::Bool`: Use great circle arcs. Default: `false`
- `width_units::String`: Width units ("pixels" or "meters"). Default: `"pixels"`
- `width_scale::Real`: Width multiplier. Default: `1`
- `width_min_pixels::Real`: Minimum width. Default: `0`
- `width_max_pixels::Real`: Maximum width. Default: `Inf`
- `opacity::Real`: Layer opacity (0-1). Default: `1`
- `pickable::Bool`: Enable interactions. Default: `false`
- `visible::Bool`: Layer visibility. Default: `true`

# Example
```julia
trips = (
    src_lng = [-122.4, -122.5],
    src_lat = [37.8, 37.7],
    dst_lng = [-73.9, -87.6],
    dst_lat = [40.7, 41.9],
    count = [100, 50]
)

layer = ArcLayer(
    data = trips,
    get_source_position = [:src_lng, :src_lat],
    get_target_position = [:dst_lng, :dst_lat],
    get_width = :count,
    get_source_color = [0, 128, 255],
    get_target_color = [255, 0, 128]
)
```
"""
Base.@kwdef struct ArcLayer <: AbstractLayer
    # Required
    data::Any
    get_source_position::Union{Symbol,Vector{Symbol}}
    get_target_position::Union{Symbol,Vector{Symbol}}

    # Identity
    id::String = "arc-" * string(uuid4())[1:8]

    # Colors
    get_source_color::Union{Vector{<:Integer},Symbol} = [0, 0, 0, 255]
    get_target_color::Union{Vector{<:Integer},Symbol} = [0, 0, 0, 255]

    # Width
    get_width::Union{Real,Symbol} = 1
    width_units::String = "pixels"
    width_scale::Real = 1
    width_min_pixels::Real = 0
    width_max_pixels::Real = Inf

    # Arc shape
    get_height::Union{Real,Symbol} = 1
    get_tilt::Union{Real,Symbol} = 0
    great_circle::Bool = false

    # Render
    opacity::Real = 1.0
    pickable::Bool = false
    visible::Bool = true
end
