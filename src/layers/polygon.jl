"""
    PolygonLayer(; data, get_polygon, kwargs...)

Renders filled and/or stroked polygons.

# Required Arguments
- `data`: Any Tables.jl-compatible data source
- `get_polygon`: Column accessor for polygon coordinates. Should reference a column
  containing arrays of `[lng, lat]` rings (outer ring, then optional holes)

# Optional Arguments
- `id::String`: Unique layer identifier
- `filled::Bool`: Draw fill. Default: `true`
- `stroked::Bool`: Draw outline. Default: `true`
- `extruded::Bool`: Extrude polygons in 3D. Default: `false`
- `wireframe::Bool`: Draw 3D wireframe. Default: `false`
- `elevation_scale::Real`: Elevation multiplier. Default: `1`
- `get_elevation::Union{Real,Symbol}`: Polygon height for extrusion. Default: `1000`
- `get_fill_color`: Fill color as `[R,G,B,A]` or column reference. Default: `[0,0,0,255]`
- `get_line_color`: Outline color as `[R,G,B,A]` or column reference. Default: `[0,0,0,255]`
- `get_line_width::Union{Real,Symbol}`: Outline width. Default: `1`
- `line_width_units::String`: Width units. Default: `"meters"`
- `line_width_scale::Real`: Width multiplier. Default: `1`
- `line_width_min_pixels::Real`: Minimum width. Default: `0`
- `line_width_max_pixels::Real`: Maximum width. Default: `Inf`
- `line_joint_rounded::Bool`: Round line joints. Default: `false`
- `line_miter_limit::Real`: Miter limit. Default: `4`
- `opacity::Real`: Layer opacity (0-1). Default: `1`
- `pickable::Bool`: Enable interactions. Default: `false`
- `visible::Bool`: Layer visibility. Default: `true`

# Example
```julia
regions = (
    polygon = [
        [[[-122.4, 37.8], [-122.5, 37.7], [-122.3, 37.7], [-122.4, 37.8]]],
        [[[-122.45, 37.85], [-122.5, 37.8], [-122.4, 37.8], [-122.45, 37.85]]]
    ],
    value = [100, 200]
)

layer = PolygonLayer(
    data = regions,
    get_polygon = :polygon,
    get_fill_color = [255, 140, 0, 100],
    get_line_color = [255, 140, 0, 255],
    get_line_width = 2
)
```
"""
Base.@kwdef struct PolygonLayer <: AbstractLayer
    # Required
    data::Any
    get_polygon::Symbol

    # Identity
    id::String = "polygon-" * string(uuid4())[1:8]

    # Fill
    filled::Bool = true
    get_fill_color::Union{Vector{<:Integer},Symbol} = [0, 0, 0, 255]

    # Stroke
    stroked::Bool = true
    get_line_color::Union{Vector{<:Integer},Symbol} = [0, 0, 0, 255]
    get_line_width::Union{Real,Symbol} = 1
    line_width_units::String = "meters"
    line_width_scale::Real = 1
    line_width_min_pixels::Real = 0
    line_width_max_pixels::Real = Inf
    line_joint_rounded::Bool = false
    line_miter_limit::Real = 4

    # 3D extrusion
    extruded::Bool = false
    wireframe::Bool = false
    elevation_scale::Real = 1
    get_elevation::Union{Real,Symbol} = 1000

    # Render
    opacity::Real = 1.0
    pickable::Bool = false
    visible::Bool = true
end
