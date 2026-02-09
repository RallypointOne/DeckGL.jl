"""
    TextLayer(; data, get_position, get_text, kwargs...)

Renders text labels at given coordinates.

# Required Arguments
- `data`: Any Tables.jl-compatible data source
- `get_position`: Column accessor for [longitude, latitude]
- `get_text`: Column accessor for text content (Symbol referencing a string column)

# Optional Arguments
- `id::String`: Unique layer identifier
- `get_size::Union{Real,Symbol}`: Text size in pixels. Default: `32`
- `get_color`: Text color as `[R,G,B,A]` or column reference. Default: `[0,0,0,255]`
- `get_angle::Union{Real,Symbol}`: Text rotation in degrees. Default: `0`
- `get_text_anchor::String`: Horizontal anchor ("start", "middle", "end"). Default: `"middle"`
- `get_alignment_baseline::String`: Vertical anchor ("top", "center", "bottom"). Default: `"center"`
- `get_pixel_offset::Vector{<:Real}`: Pixel offset [x, y]. Default: `[0, 0]`
- `background::Bool`: Draw background. Default: `false`
- `get_background_color`: Background color. Default: `[255, 255, 255, 255]`
- `background_padding::Vector{<:Real}`: Background padding [x, y]. Default: `[0, 0]`
- `font_family::String`: Font family. Default: `"Monaco, monospace"`
- `font_weight::Union{String,Int}`: Font weight. Default: `"normal"`
- `line_height::Real`: Line height multiplier. Default: `1`
- `billboard::Bool`: Always face camera. Default: `true`
- `size_scale::Real`: Size multiplier. Default: `1`
- `size_units::String`: Size units ("pixels" or "meters"). Default: `"pixels"`
- `size_min_pixels::Real`: Minimum size. Default: `0`
- `size_max_pixels::Real`: Maximum size. Default: `Inf`
- `opacity::Real`: Layer opacity (0-1). Default: `1`
- `pickable::Bool`: Enable interactions. Default: `false`
- `visible::Bool`: Layer visibility. Default: `true`

# Example
```julia
cities = (
    lng = [-122.4, -73.9, -87.6],
    lat = [37.8, 40.7, 41.9],
    name = ["San Francisco", "New York", "Chicago"],
    population = [883000, 8336000, 2693000]
)

layer = TextLayer(
    data = cities,
    get_position = [:lng, :lat],
    get_text = :name,
    get_size = 16,
    get_color = [0, 0, 0, 255],
    get_text_anchor = "middle",
    get_alignment_baseline = "center"
)
```
"""
Base.@kwdef struct TextLayer <: AbstractLayer
    # Required
    data::Any
    get_position::Union{Symbol,Vector{Symbol}}
    get_text::Symbol

    # Identity
    id::String = "text-" * string(uuid4())[1:8]

    # Text style
    get_size::Union{Real,Symbol} = 32
    get_color::Union{Vector{<:Integer},Symbol} = [0, 0, 0, 255]
    get_angle::Union{Real,Symbol} = 0
    get_text_anchor::String = "middle"
    get_alignment_baseline::String = "center"
    get_pixel_offset::Vector{<:Real} = [0, 0]

    # Font
    font_family::String = "Monaco, monospace"
    font_weight::Union{String,Int} = "normal"
    line_height::Real = 1

    # Background
    background::Bool = false
    get_background_color::Union{Vector{<:Integer},Symbol} = [255, 255, 255, 255]
    background_padding::Vector{<:Real} = [0, 0]

    # Size
    billboard::Bool = true
    size_scale::Real = 1
    size_units::String = "pixels"
    size_min_pixels::Real = 0
    size_max_pixels::Real = Inf

    # Render
    opacity::Real = 1.0
    pickable::Bool = false
    visible::Bool = true
end
