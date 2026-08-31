#-----------------------------------------------------------------------------# Prop names
# deck.gl props are camelCase. Julia keyword arguments read better as snake_case, so
# accept either and normalize here. Leading underscores mark deck.gl's own internal
# props (`_normalize`, `_dataDiff`) and are preserved.
function camelcase(s::Symbol)
    str = String(s)
    occursin('_', str) || return s
    lead = length(str) - length(lstrip(str, '_'))
    parts = split(str[lead+1:end], '_'; keepempty=false)
    isempty(parts) && return s
    return Symbol('_'^lead, parts[1], join(uppercasefirst.(@view parts[2:end])))
end

# Props DeckGL.jl adds on top of deck.gl's own. `tooltip` names the columns picking
# should show, which deck.gl cannot express per-layer. They are accepted by layers,
# reported by `props`, and stripped before the deck.gl constructor is written.
const EXTRA_LAYER_PROPS = (:tooltip,)
const EMPTY_PROPS = Symbol[]

# Props are checked against deck.gl's own tables but never rejected: a prop this
# version of the bindings does not know about may be perfectly valid in a newer
# deck.gl, and refusing to send it would be worse than a typo slipping through.
function check_props(name::Symbol, table::Dict{Symbol,Vector{Symbol}}, props, what::AbstractString, extra = ())
    known = get(table, name, nothing)
    known === nothing && return
    # deck.gl's `View` classes carry no `defaultProps`, so there is nothing to check
    # against and every prop would look unrecognized.
    isempty(known) && return
    unknown = sort!([k for k in keys(props) if !(k in known) && !(k in extra)])
    isempty(unknown) && return
    @warn "Unrecognized $what $(length(unknown) == 1 ? "prop" : "props") for $name in deck.gl v$DECKGL_VERSION; \
           sending anyway. Call `DeckGL.props($name)` to list the valid ones." unknown
end

#-----------------------------------------------------------------------------# Colors
"""
    DeckGL.is_color_prop(class, prop) -> Bool

Whether `prop` holds a color for a given layer, widget, or view.

The answer cannot be read off the prop's name: `color` is RGB(A) on `TerrainLayer` but a
CSS string on `IconWidget`, and `getColorWeight` is a number despite how it reads. The
table this consults is generated from deck.gl's own prop types.
"""
is_color_prop(class::Symbol, prop::Symbol) = prop in get(COLOR_PROPS, class, EMPTY_PROPS)

"""
    DeckGL.to_color(x)

Widen `x` into the `[R, G, B]` or `[R, G, B, A]` bytes deck.gl expects. Applied to every
prop deck.gl types as a color, which includes list-valued ones such as `color_range`.

Hex strings are understood out of the box; loading Colors.jl adds `Colorant`s, so
`colorant"tomato"` and `RGBA(1, 0, 0, 0.5)` become valid color props.
"""
to_color(x) = x
to_color(v::AbstractVector{<:Real}) = v          # already RGB(A) components
to_color(v::AbstractVector) = map(to_color, v)   # a list of colors, e.g. `color_range`

function to_color(s::AbstractString)
    hex = lstrip(s, '#')
    length(hex) in (6, 8) ||
        throw(ArgumentError("expected a hex color like \"#ff8800\" or \"#ff8800cc\", got $(repr(s))"))
    return [parse(Int, hex[i:i+1]; base=16) for i in 1:2:length(hex)]
end

function normalize_props(class::Symbol, kw)
    props = Dict{Symbol,Any}()
    for (key, value) in kw
        value === nothing && continue
        prop = camelcase(key)
        props[prop] = is_color_prop(class, prop) ? to_color(value) : value
    end
    return props
end

#-----------------------------------------------------------------------------# Layer
"""
    Layer{name}

A deck.gl layer: a name and a bag of props, serialized into a `new deck.<name>(...)`
call. The concrete layers are `const` aliases of this type, so `ScatterplotLayer` is
exactly `Layer{:ScatterplotLayer}` and `layer isa ScatterplotLayer` works as expected.

There is deliberately no Julia-side struct field per deck.gl prop. deck.gl's own
`defaultProps` tables are the source of truth for which props exist (see
`src/metadata.jl`), and any prop left unset here is left unset in the output so that
deck.gl applies its own default rather than one copied into Julia and left to drift.
"""
struct Layer{name}
    props::Dict{Symbol,Any}
end

function (::Type{Layer{name}})(; kw...) where {name}
    props = normalize_props(name, kw)
    check_props(name, LAYER_PROPS, props, "layer", EXTRA_LAYER_PROPS)
    # A tooltip is picking, so it implies picking unless the user says otherwise.
    haskey(props, :tooltip) && get!(props, :pickable, true)
    return Layer{name}(props)
end

#-----------------------------------------------------------------------------# Widget
"""
    Widget{name}

A deck.gl UI widget (zoom buttons, compass, fullscreen toggle, ...). Concrete widgets
are `const` aliases, e.g. `ZoomWidget === Widget{:ZoomWidget}`.
"""
struct Widget{name}
    props::Dict{Symbol,Any}
end

function (::Type{Widget{name}})(; kw...) where {name}
    props = normalize_props(name, kw)
    check_props(name, WIDGET_PROPS, props, "widget")
    return Widget{name}(props)
end

#-----------------------------------------------------------------------------# View
"""
    View{name}

A deck.gl view: the camera model the layers are rendered through. `MapView` is the
geospatial default; `OrthographicView` and `OrbitView` render non-geographic data in
Cartesian coordinates. Concrete views are `const` aliases, e.g. `MapView === View{:MapView}`.
"""
struct View{name}
    props::Dict{Symbol,Any}
end

function (::Type{View{name}})(; kw...) where {name}
    props = normalize_props(name, kw)
    check_props(name, VIEW_PROPS, props, "view")
    return View{name}(props)
end

#-----------------------------------------------------------------------------# Aliases
# `ScatterplotLayer` is exactly `Layer{:ScatterplotLayer}`, so dispatch and `isa` work as
# they would on a hand-written struct. The names themselves are exported from `DeckGL.jl`.
for (names, T) in ((LAYER_NAMES, :Layer), (WIDGET_NAMES, :Widget), (VIEW_NAMES, :View))
    for name in names
        @eval const $name = $T{$(QuoteNode(name))}
    end
end

# Layer docstrings are generated rather than transcribed: a hand-written prop table
# per layer is a copy of deck.gl's documentation that silently goes stale.
for name in LAYER_NAMES
    accessors = LAYER_ACCESSORS[name]
    doc = """
            $name(; data, props...)

        The deck.gl [`$name`]($(LAYER_DOCS[name])).

        Props pass straight through to deck.gl and may be written `snake_case` or
        `camelCase` — `get_fill_color` and `getFillColor` are the same prop. Anything
        left unset keeps deck.gl's own default. Use `JS` for props that must
        be JavaScript functions.

        `data` is anything Tables.jl understands, a GeoJSON object, or a URL string.

        Data accessors, which may name a column of `data` as a `Symbol` (or a list of
        `Symbol`s to combine several columns into one vector):

        $(join(("- `$(a)`" for a in accessors), "\n    "))

        `DeckGL.props($name)` lists every prop deck.gl accepts here.
        """
    @eval @doc $doc $name
end

#-----------------------------------------------------------------------------# Introspection
"""
    DeckGL.props(T) -> Vector{Symbol}

Every prop a layer, widget, or view type accepts: deck.gl v$(DECKGL_VERSION)'s own, plus
the few DeckGL.jl adds (`tooltip`).

### Examples
```julia
DeckGL.props(ScatterplotLayer)
```
"""
props(::Type{Layer{name}}) where {name} =
    sort!([get(LAYER_PROPS, name, EMPTY_PROPS); EXTRA_LAYER_PROPS...])
props(::Type{Widget{name}}) where {name} = get(WIDGET_PROPS, name, EMPTY_PROPS)
props(::Type{View{name}}) where {name} = get(VIEW_PROPS, name, EMPTY_PROPS)
props(x::Union{Layer,Widget,View}) = props(typeof(x))

"""
    DeckGL.accessors(T) -> Vector{Symbol}

The props of a layer that deck.gl evaluates per data record, and which may therefore
name a column of the layer's `data`.

### Examples
```julia
DeckGL.accessors(ScatterplotLayer)
```
"""
accessors(::Type{Layer{name}}) where {name} = get(LAYER_ACCESSORS, name, EMPTY_PROPS)
accessors(x::Layer) = accessors(typeof(x))

typename(::Union{Layer{name},Type{Layer{name}}}) where {name} = name
typename(::Union{Widget{name},Type{Widget{name}}}) where {name} = name
typename(::Union{View{name},Type{View{name}}}) where {name} = name
#-----------------------------------------------------------------------------# ViewState
"""
    ViewState(; props...)

The camera position layers are rendered from.

The meaningful props depend on the view: `longitude`, `latitude`, `zoom`, `pitch` and
`bearing` for the geospatial `MapView`; `target` and `zoom` for `OrthographicView` and
`OrbitView`. Nothing is defaulted here, so anything omitted is omitted from the output.

### Examples
```julia
ViewState(longitude=-122.4, latitude=37.8, zoom=11, pitch=45)
ViewState(target=[0, 0, 0], zoom=3)          # OrthographicView / OrbitView
```
"""
struct ViewState
    props::Dict{Symbol,Any}
end

ViewState(; kw...) = ViewState(normalize_props(:ViewState, kw))

typename(::Union{ViewState,Type{ViewState}}) = :ViewState

# Layers, widgets, views and view states all hold their props in a `props` field, so they
# share one set of accessors.
const Spec = Union{Layer,Widget,View,ViewState}

Base.getindex(x::Spec, k::Symbol) = x.props[camelcase(k)]
Base.get(x::Spec, k::Symbol, default) = get(x.props, camelcase(k), default)
Base.haskey(x::Spec, k::Symbol) = haskey(x.props, camelcase(k))

# Output has to be reproducible, so props are always emitted in a fixed order.
sorted_props(x) = sort!(collect(x.props); by = first)

#-----------------------------------------------------------------------------# Deck
"""
    Deck(layers; initial_view_state, map_style, controller, widgets, views, props...)

A deck.gl visualization: the layers to draw, the camera to draw them from, and the
page furniture around them.

### Arguments
- `layers`: one `Layer` or an iterable of them, drawn in order

### Keyword Arguments
- `initial_view_state::ViewState`: starting camera. With no explicit `views`, deck.gl
  renders through a `MapView`, which needs a `longitude` and `latitude`; those two are
  filled in at the origin if left out. Default: world view at zoom 1
- `map_style`: URL of a MapLibre style to draw a basemap beneath the layers, or
  `nothing` for no basemap. A basemap always requires network access at view time,
  for both MapLibre itself and the map tiles
- `controller`: enable pan/zoom/rotate. Default: `true`
- `widgets`: `Widget`s to overlay
- `views`: `View`s to render through. Default: deck.gl's own `MapView`
- `props...`: any other deck.gl `Deck` prop, e.g. `on_click=JS("info => ...")`

### Examples
```julia
deck = Deck(
    ScatterplotLayer(data=df, get_position=[:lng, :lat], get_radius=100),
    initial_view_state = ViewState(longitude=-122.4, latitude=37.8, zoom=11),
    widgets = [ZoomWidget(), CompassWidget()],
)
```
"""
struct Deck
    layers::Vector{Layer}
    initial_view_state::ViewState
    views::Vector{View}
    widgets::Vector{Widget}
    map_style::Union{Nothing,String}
    props::Dict{Symbol,Any}
end

function Deck(layers;
        initial_view_state::ViewState = ViewState(zoom=1),
        views = View[],
        widgets = Widget[],
        map_style::Union{Nothing,AbstractString} = nothing,
        controller = true,
        kw...)
    ls = layers isa Layer ? Layer[layers] : collect(Layer, layers)
    vs = collect(View, views)
    props = normalize_props(:Deck, kw)
    controller === nothing || (props[:controller] = controller)
    return Deck(ls, map_view_state(initial_view_state, vs), vs, collect(Widget, widgets),
                map_style === nothing ? nothing : String(map_style), props)
end

# A `MapView` -- deck.gl's default when no view is given -- cannot place the camera
# without a longitude and latitude. Any other view is positioned by `target` instead and
# is left exactly as written.
is_map_view(views) = isempty(views) || all(v -> typename(v) === :MapView, views)

function map_view_state(state::ViewState, views::Vector{View})
    is_map_view(views) || return state
    (haskey(state, :longitude) && haskey(state, :latitude)) && return state
    filled = copy(state.props)
    get!(filled, :longitude, 0.0)
    get!(filled, :latitude, 0.0)
    return ViewState(filled)
end
