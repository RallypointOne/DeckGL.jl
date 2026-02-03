"""
    GeoJsonLayer(; data, kwargs...)

Renders GeoJSON data as points, lines, and polygons.

This is a composite layer that automatically renders GeoJSON features using
the appropriate sub-layers (ScatterplotLayer, PathLayer, PolygonLayer).

# Required Arguments
- `data`: GeoJSON data as a Dict, String (JSON), or URL to GeoJSON file

# Optional Arguments
- `id::String`: Unique layer identifier
- `filled::Bool`: Fill polygons. Default: `true`
- `stroked::Bool`: Draw polygon outlines. Default: `true`
- `extruded::Bool`: Extrude polygons in 3D. Default: `false`
- `wireframe::Bool`: Draw 3D wireframe. Default: `false`
- `point_type::String`: Point rendering type ("circle", "icon", "text"). Default: `"circle"`
- `get_fill_color`: Fill color. Default: `[0, 0, 0, 255]`
- `get_line_color`: Line/stroke color. Default: `[0, 0, 0, 255]`
- `get_line_width::Union{Real,Symbol}`: Line width. Default: `1`
- `get_point_radius::Union{Real,Symbol}`: Point radius. Default: `1`
- `get_elevation::Union{Real,Symbol}`: Polygon elevation for 3D. Default: `1000`
- `line_width_units::String`: Line width units. Default: `"meters"`
- `line_width_scale::Real`: Line width multiplier. Default: `1`
- `line_width_min_pixels::Real`: Minimum line width. Default: `0`
- `line_width_max_pixels::Real`: Maximum line width. Default: `Inf`
- `line_joint_rounded::Bool`: Round line joints. Default: `false`
- `line_cap_rounded::Bool`: Round line caps. Default: `false`
- `line_miter_limit::Real`: Miter limit. Default: `4`
- `point_radius_units::String`: Point radius units. Default: `"meters"`
- `point_radius_scale::Real`: Point radius multiplier. Default: `1`
- `point_radius_min_pixels::Real`: Minimum point radius. Default: `0`
- `point_radius_max_pixels::Real`: Maximum point radius. Default: `Inf`
- `elevation_scale::Real`: Elevation multiplier. Default: `1`
- `opacity::Real`: Layer opacity (0-1). Default: `1`
- `pickable::Bool`: Enable interactions. Default: `false`
- `visible::Bool`: Layer visibility. Default: `true`

# Example
```julia
# GeoJSON as a Dict
geojson = Dict(
    "type" => "FeatureCollection",
    "features" => [
        Dict(
            "type" => "Feature",
            "geometry" => Dict(
                "type" => "Point",
                "coordinates" => [-122.4, 37.8]
            ),
            "properties" => Dict("name" => "San Francisco")
        )
    ]
)

layer = GeoJsonLayer(
    data = geojson,
    get_fill_color = [255, 0, 0, 100],
    get_line_color = [255, 0, 0, 255],
    get_point_radius = 100
)

# Or load from URL
layer = GeoJsonLayer(
    data = "https://example.com/data.geojson",
    filled = true,
    stroked = true
)
```
"""
Base.@kwdef struct GeoJsonLayer <: AbstractLayer
    # Required - can be Dict, JSON string, or URL
    data::Any

    # Identity
    id::String = "geojson-" * string(uuid4())[1:8]

    # Polygon rendering
    filled::Bool = true
    stroked::Bool = true
    extruded::Bool = false
    wireframe::Bool = false
    elevation_scale::Real = 1
    get_elevation::Union{Real,Symbol} = 1000

    # Point rendering
    point_type::String = "circle"
    get_point_radius::Union{Real,Symbol} = 1
    point_radius_units::String = "meters"
    point_radius_scale::Real = 1
    point_radius_min_pixels::Real = 0
    point_radius_max_pixels::Real = Inf

    # Line/stroke rendering
    get_line_width::Union{Real,Symbol} = 1
    line_width_units::String = "meters"
    line_width_scale::Real = 1
    line_width_min_pixels::Real = 0
    line_width_max_pixels::Real = Inf
    line_joint_rounded::Bool = false
    line_cap_rounded::Bool = false
    line_miter_limit::Real = 4

    # Colors
    get_fill_color::Union{Vector{<:Integer},Symbol,String} = [0, 0, 0, 255]
    get_line_color::Union{Vector{<:Integer},Symbol,String} = [0, 0, 0, 255]

    # Render
    opacity::Real = 1.0
    pickable::Bool = false
    visible::Bool = true
end
