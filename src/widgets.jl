#-----------------------------------------------------------------------------# ZoomWidget
"""
    ZoomWidget(; id="zoom", placement="top-right", orientation="vertical", transition_duration=200)

Adds +/- zoom buttons to the map.

# Keyword Arguments
- `id::String`: Widget identifier. Default: `"zoom"`
- `placement::String`: Widget position (`"top-left"`, `"top-right"`, `"bottom-left"`, `"bottom-right"`). Default: `"top-right"`
- `orientation::String`: Button layout (`"vertical"` or `"horizontal"`). Default: `"vertical"`
- `transition_duration::Int`: Zoom animation duration in ms. Default: `200`

### Examples
```julia
Deck(layer, widgets=[ZoomWidget()])
Deck(layer, widgets=[ZoomWidget(placement="top-left", orientation="horizontal")])
```
"""
Base.@kwdef struct ZoomWidget <: AbstractWidget
    id::String = "zoom"
    placement::String = "top-right"
    orientation::String = "vertical"
    transition_duration::Int = 200
end

#-----------------------------------------------------------------------------# CompassWidget
"""
    CompassWidget(; id="compass", placement="top-right", transition_duration=200)

Displays a compass rose showing the current bearing. Click to reset bearing to north.

# Keyword Arguments
- `id::String`: Widget identifier. Default: `"compass"`
- `placement::String`: Widget position (`"top-left"`, `"top-right"`, `"bottom-left"`, `"bottom-right"`). Default: `"top-right"`
- `transition_duration::Int`: Reset animation duration in ms. Default: `200`

### Examples
```julia
Deck(layer, widgets=[CompassWidget()])
Deck(layer, widgets=[CompassWidget(placement="bottom-right")])
```
"""
Base.@kwdef struct CompassWidget <: AbstractWidget
    id::String = "compass"
    placement::String = "top-right"
    transition_duration::Int = 200
end

#-----------------------------------------------------------------------------# FullscreenWidget
"""
    FullscreenWidget(; id="fullscreen", placement="top-right")

Adds a button to toggle fullscreen mode.

# Keyword Arguments
- `id::String`: Widget identifier. Default: `"fullscreen"`
- `placement::String`: Widget position (`"top-left"`, `"top-right"`, `"bottom-left"`, `"bottom-right"`). Default: `"top-right"`

### Examples
```julia
Deck(layer, widgets=[FullscreenWidget()])
Deck(layer, widgets=[FullscreenWidget(placement="top-left")])
```
"""
Base.@kwdef struct FullscreenWidget <: AbstractWidget
    id::String = "fullscreen"
    placement::String = "top-right"
end
