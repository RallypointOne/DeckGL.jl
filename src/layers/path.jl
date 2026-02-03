"""
    PathLayer(; data, get_path, kwargs...)

Renders sequences of coordinates as paths/polylines.

# Required Arguments
- `data`: Any Tables.jl-compatible data source
- `get_path`: Column accessor for path coordinates. Should reference a column
  containing arrays of `[lng, lat]` pairs, e.g., `[[lng1,lat1], [lng2,lat2], ...]`

# Optional Arguments
- `id::String`: Unique layer identifier
- `get_color`: Path color as `[R,G,B,A]` or column reference. Default: `[0,0,0,255]`
- `get_width::Union{Real,Symbol}`: Path width in pixels. Default: `1`
- `width_units::String`: Width units ("pixels" or "meters"). Default: `"pixels"`
- `width_scale::Real`: Width multiplier. Default: `1`
- `width_min_pixels::Real`: Minimum width. Default: `0`
- `width_max_pixels::Real`: Maximum width. Default: `Inf`
- `cap_rounded::Bool`: Round line caps. Default: `false`
- `joint_rounded::Bool`: Round line joints. Default: `false`
- `billboard::Bool`: Always face camera. Default: `false`
- `miter_limit::Real`: Miter limit for sharp corners. Default: `4`
- `opacity::Real`: Layer opacity (0-1). Default: `1`
- `pickable::Bool`: Enable interactions. Default: `false`
- `visible::Bool`: Layer visibility. Default: `true`

# Example
```julia
routes = (
    path = [
        [[-122.4, 37.8], [-122.5, 37.7], [-122.3, 37.9]],
        [[-122.45, 37.75], [-122.35, 37.85]]
    ],
    name = ["Route A", "Route B"]
)

layer = PathLayer(
    data = routes,
    get_path = :path,
    get_color = [0, 128, 255, 200],
    get_width = 5,
    cap_rounded = true
)
```
"""
Base.@kwdef struct PathLayer <: AbstractLayer
    # Required
    data::Any
    get_path::Symbol

    # Identity
    id::String = "path-" * string(uuid4())[1:8]

    # Color
    get_color::Union{Vector{<:Integer},Symbol} = [0, 0, 0, 255]

    # Width
    get_width::Union{Real,Symbol} = 1
    width_units::String = "pixels"
    width_scale::Real = 1
    width_min_pixels::Real = 0
    width_max_pixels::Real = Inf

    # Line style
    cap_rounded::Bool = false
    joint_rounded::Bool = false
    billboard::Bool = false
    miter_limit::Real = 4

    # Render
    opacity::Real = 1.0
    pickable::Bool = false
    visible::Bool = true
end
