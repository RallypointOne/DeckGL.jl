#-----------------------------------------------------------------------------# ViewState
"""
    ViewState(; longitude=0.0, latitude=0.0, zoom=1.0, pitch=0.0, bearing=0.0)

Camera/viewport configuration for a deck.gl visualization.

# Fields
- `longitude::Float64`: Center longitude
- `latitude::Float64`: Center latitude
- `zoom::Float64`: Zoom level (0-20+)
- `pitch::Float64`: Tilt angle in degrees (0-60)
- `bearing::Float64`: Rotation angle in degrees (0-360)
"""
Base.@kwdef struct ViewState
    longitude::Float64 = 0.0
    latitude::Float64 = 0.0
    zoom::Float64 = 1.0
    pitch::Float64 = 0.0
    bearing::Float64 = 0.0
end

#-----------------------------------------------------------------------------# AbstractLayer
"""
    AbstractLayer

Abstract supertype for all deck.gl layers.
"""
abstract type AbstractLayer end

# Get the deck.gl layer type name (e.g., "ScatterplotLayer")
layer_type(::T) where {T<:AbstractLayer} = string(nameof(T))

#-----------------------------------------------------------------------------# Deck
"""
    Deck(layers; initial_view_state=ViewState(), map_style=nothing, controller=true)

The top-level container representing a deck.gl visualization.

# Arguments
- `layers`: A single `AbstractLayer` or a vector of layers

# Keyword Arguments
- `initial_view_state::ViewState`: Camera configuration
- `map_style::Union{String,Nothing}`: Map tile style URL (Mapbox/MapLibre/Carto)
- `controller::Bool`: Enable pan/zoom/rotate controls

# Example
```julia
layer = ScatterplotLayer(data=df, get_position=[:lng, :lat])
deck = Deck(layer, initial_view_state=ViewState(longitude=-122.4, latitude=37.8, zoom=11))
```
"""
struct Deck
    layers::Vector{AbstractLayer}
    initial_view_state::ViewState
    map_style::Union{String,Nothing}
    controller::Bool
end

function Deck(layers;
    initial_view_state::ViewState = ViewState(),
    map_style::Union{String,Nothing} = nothing,
    controller::Bool = true
)
    layers_vec = layers isa AbstractLayer ? [layers] : collect(AbstractLayer, layers)
    Deck(layers_vec, initial_view_state, map_style, controller)
end
