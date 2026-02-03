"""
    ScatterplotLayer(; data, get_position, kwargs...)

Renders circles at given coordinates.

# Required Arguments
- `data`: Any Tables.jl-compatible data source (DataFrame, NamedTuple of vectors, etc.)
- `get_position`: Column accessor for [longitude, latitude] positions.
  Can be a `Symbol` for a column containing coordinate tuples/arrays,
  or a `Vector{Symbol}` like `[:lng, :lat]` for separate columns.

# Optional Arguments
- `id::String`: Unique layer identifier (auto-generated if not provided)
- `get_radius::Union{Real,Symbol}`: Circle radius in meters. Default: `1`
- `get_fill_color`: Fill color as `[R,G,B]` or `[R,G,B,A]` (0-255), or a `Symbol` for data-driven color
- `get_line_color`: Outline color (same format as fill_color)
- `get_line_width::Union{Real,Symbol}`: Outline width in pixels. Default: `1`
- `radius_scale::Real`: Global radius multiplier. Default: `1`
- `radius_min_pixels::Real`: Minimum radius in pixels. Default: `0`
- `radius_max_pixels::Real`: Maximum radius in pixels. Default: `Inf`
- `line_width_units::String`: Units for line width ("pixels" or "meters"). Default: `"pixels"`
- `line_width_scale::Real`: Global line width multiplier. Default: `1`
- `stroked::Bool`: Draw outline. Default: `false`
- `filled::Bool`: Draw fill. Default: `true`
- `billboard::Bool`: If true, circles always face camera. Default: `false`
- `opacity::Real`: Layer opacity (0-1). Default: `1`
- `pickable::Bool`: Enable hover/click interactions. Default: `false`
- `visible::Bool`: Layer visibility. Default: `true`

# Example
```julia
using DataFrames

df = DataFrame(
    longitude = [-122.4, -122.5, -122.3],
    latitude = [37.8, 37.7, 37.9],
    size = [100, 200, 150]
)

layer = ScatterplotLayer(
    data = df,
    get_position = [:longitude, :latitude],
    get_radius = :size,
    get_fill_color = [255, 140, 0, 200]
)
```
"""
Base.@kwdef struct ScatterplotLayer <: AbstractLayer
    # Required
    data::Any
    get_position::Union{Symbol,Vector{Symbol}}

    # Identity
    id::String = "scatterplot-" * string(uuid4())[1:8]

    # Radius
    get_radius::Union{Real,Symbol} = 1
    radius_scale::Real = 1
    radius_min_pixels::Real = 0
    radius_max_pixels::Real = Inf

    # Fill
    filled::Bool = true
    get_fill_color::Union{Vector{<:Integer},Symbol} = [0, 0, 0, 255]

    # Stroke
    stroked::Bool = false
    get_line_color::Union{Vector{<:Integer},Symbol} = [0, 0, 0, 255]
    get_line_width::Union{Real,Symbol} = 1
    line_width_units::String = "pixels"
    line_width_scale::Real = 1
    line_width_min_pixels::Real = 0
    line_width_max_pixels::Real = Inf

    # Render
    billboard::Bool = false
    opacity::Real = 1.0
    pickable::Bool = false
    visible::Bool = true
end
