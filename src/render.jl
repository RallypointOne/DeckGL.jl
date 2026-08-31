# Read at precompile time, so the cache has to be invalidated when they change.
const TEMPLATE_PATH = joinpath(@__DIR__, "assets", "template.html")
const PRELUDE_PATH = joinpath(@__DIR__, "assets", "prelude.js")
include_dependency(TEMPLATE_PATH)
include_dependency(PRELUDE_PATH)

# Split at the script placeholder so a page can be streamed out around it rather than
# built as one string and substituted into.
const TEMPLATE_HEAD, TEMPLATE_TAIL = split(read(TEMPLATE_PATH, String), "{{SCRIPT}}")
const PRELUDE = read(PRELUDE_PATH, String)

#-----------------------------------------------------------------------------# deck.gl bundle
"""
    DeckGL.bundle_path() -> String

Path to the deck.gl bundle in the `deckgl` artifact, downloading it on first use.
"""
bundle_path() = joinpath(artifact"deckgl", "package", "dist.min.js")

"""
    DeckGL.stylesheet_path() -> String

Path to the deck.gl widget stylesheet in the `deckgl` artifact.
"""
stylesheet_path() = joinpath(artifact"deckgl", "package", "dist", "stylesheet.css")

const CDN_BUNDLE = "https://unpkg.com/deck.gl@$DECKGL_VERSION/dist.min.js"
const CDN_STYLESHEET = "https://unpkg.com/deck.gl@$DECKGL_VERSION/dist/stylesheet.css"
const CDN_MAPLIBRE_JS = "https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js"
const CDN_MAPLIBRE_CSS = "https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css"

# deck.gl bundles its dependencies with one exception: the shipped `dist.min.js` reads
# `globalThis.h3`, so a page drawing H3 cells has to load h3-js itself. Everything else
# geo-layers depends on, a5-js included, is compiled in. The version tracks the range
# `@deck.gl/geo-layers` declares for the pinned DECKGL_VERSION.
const PEER_SCRIPTS = Dict{Symbol,String}(
    :H3HexagonLayer => "https://unpkg.com/h3-js@4.4.0/dist/h3-js.umd.js",
    :H3ClusterLayer => "https://unpkg.com/h3-js@4.4.0/dist/h3-js.umd.js",
)

"""
    DeckGL.peer_scripts(deck) -> Vector{String}

URLs of the libraries `deck`'s layers need but deck.gl does not bundle.
"""
peer_scripts(deck::Deck) =
    unique!([PEER_SCRIPTS[typename(l)] for l in deck.layers if haskey(PEER_SCRIPTS, typename(l))])

#-----------------------------------------------------------------------------# Layer JavaScript
# Props DeckGL understands but deck.gl does not, stripped before emitting.
const INTERNAL_LAYER_PROPS = (:data, EXTRA_LAYER_PROPS...)

# Ids only have to be unique within a deck. Numbering by position is deterministic --
# the same code produces the same page every time, in any session -- which a counter or
# a random id is not. Computed once per layer: the tooltip table is filed under the same
# key the layer is constructed with, and picking looks it up by that key.
layer_id(layer::Layer, index::Integer) =
    string(get(layer.props, :id, "$(typename(layer))-$index"))

print_local(io::IO, value::Union{Vector{Float32},Vector{UInt8}}) = print_typed_array(io, value)
print_local(io::IO, value) = print_js(io, value)

function print_data(io::IO, d::LayerData)
    d.istable || return print_js(io, d.passthrough)
    d.aggregating && return print(io, "DG.range(", d.nrows, ")")
    print(io, "{length:", d.nrows, ",attributes:{")
    for (i, attribute) in enumerate(d.attributes)
        i > 1 && print(io, ',')
        print(io, attribute.prop, ":{value:")
        print_typed_array(io, attribute.buffer)
        print(io, ",size:", attribute.size)
        # deck.gl reads color attributes as normalized bytes. Saying so explicitly stops
        # it warning about a buffer whose exact type it did not create.
        attribute.buffer isa Vector{UInt8} && print(io, ",normalized:true")
        print(io, '}')
    end
    print(io, "}}")
end

function print_layer(io::IO, layer::Layer, id::AbstractString, d::LayerData)
    # Columns the accessors close over are scoped to the layer that uses them.
    if !isempty(d.locals)
        print(io, "(() => {\n    ")
        for (name, value) in d.locals
            print(io, "const ", name, " = ")
            print_local(io, value)
            print(io, ";\n    ")
        end
        print(io, "return ")
    end

    print(io, "new deck.", typename(layer), "({id:")
    print_js(io, id)
    print(io, ",data:")
    print_data(io, d)
    for (prop, value) in sorted_props(layer)
        (prop in INTERNAL_LAYER_PROPS || prop === :id) && continue
        prop in d.packed && continue  # already uploaded as a binary attribute
        print(io, ',', prop, ':')
        override = get(d.overrides, prop, nothing)
        override === nothing ? print_js(io, value) : print(io, override)
    end
    print(io, "})")

    isempty(d.locals) || print(io, ";\n  })()")
    return nothing
end

function print_spec(io::IO, x::Union{Widget,View})
    print(io, "new deck.", typename(x), "({")
    for (i, (prop, value)) in enumerate(sorted_props(x))
        i > 1 && print(io, ',')
        print(io, prop, ':')
        print_js(io, value)
    end
    print(io, "})")
end

function print_tooltip(io::IO, table)
    names, columns = table
    # Picking an aggregation layer selects a bin, which describes itself.
    isempty(names) && return print(io, "{object:true}")
    print(io, "{keys:")
    print_js(io, names)
    print(io, ",cols:[")
    for (i, column) in enumerate(columns)
        i > 1 && print(io, ',')
        print_local(io, column)
    end
    print(io, "]}")
end

#-----------------------------------------------------------------------------# Deck JavaScript
"""
    to_js(deck::Deck) -> String
    to_js(io::IO, deck::Deck)

The JavaScript that builds and mounts `deck`.

The page carries no spec language and no interpreter: layers are emitted as the
`new deck.ScatterplotLayer({...})` calls a hand-written page would contain, which
means the output can be read, pasted into a console, and debugged directly.

The `IO` form streams, encoding attribute buffers straight into the output instead of
materializing the page -- which at a million rows is mostly base64 -- as a string first.
"""
function to_js(io::IO, deck::Deck)
    print(io, PRELUDE, "\nDG.mount({mapStyle:")
    print_js(io, deck.map_style)
    print(io, ",deck:{initialViewState:")
    print_js(io, deck.initial_view_state.props)

    print(io, ",\n  layers:[")
    tooltips = Pair{String,Any}[]
    for (i, layer) in enumerate(deck.layers)
        i > 1 && print(io, ",\n  ")
        resolved = resolve_data(layer)
        id = layer_id(layer, i)
        print_layer(io, layer, id, resolved)
        resolved.tooltip === nothing || push!(tooltips, id => resolved.tooltip)
    end
    print(io, ']')

    for (name, specs) in ("views" => deck.views, "widgets" => deck.widgets)
        isempty(specs) && continue
        print(io, ",\n  ", name, ":[")
        for (i, spec) in enumerate(specs)
            i > 1 && print(io, ',')
            print_spec(io, spec)
        end
        print(io, ']')
    end

    for (prop, value) in sorted_props(deck)
        print(io, ",\n  ", prop, ':')
        print_js(io, value)
    end

    if !isempty(tooltips)
        print(io, ",\n  getTooltip:DG.tooltip({")
        for (i, (id, table)) in enumerate(tooltips)
            i > 1 && print(io, ',')
            print_js(io, id)
            print(io, ':')
            print_tooltip(io, table)
        end
        print(io, "})")
    end

    print(io, "}});\n")
    return nothing
end

to_js(deck::Deck) = sprint(to_js, deck)

#-----------------------------------------------------------------------------# HTML
function asset_tags(deck::Deck, bundle::Symbol, scripts)
    tags = String[]
    needs_widgets = !isempty(deck.widgets)
    # Peer libraries and anything the user asked for load first, so that deck.gl finds
    # them already defined.
    for url in [peer_scripts(deck); collect(String, scripts)]
        push!(tags, """<script src="$url"></script>""")
    end
    if bundle === :local
        push!(tags, "<script>\n$(read(bundle_path(), String))\n</script>")
        needs_widgets && push!(tags, "<style>\n$(read(stylesheet_path(), String))\n</style>")
    elseif bundle === :cdn
        push!(tags, """<script src="$CDN_BUNDLE"></script>""")
        needs_widgets && push!(tags, """<link href="$CDN_STYLESHEET" rel="stylesheet">""")
    else
        throw(ArgumentError("bundle must be :cdn or :local, got $(repr(bundle))"))
    end
    # A basemap is never offline: MapLibre and the map tiles are both fetched at view time.
    if deck.map_style !== nothing
        push!(tags, """<link href="$CDN_MAPLIBRE_CSS" rel="stylesheet">""")
        push!(tags, """<script src="$CDN_MAPLIBRE_JS"></script>""")
    end
    return join(tags, "\n")
end

escape_html(s::AbstractString) =
    replace(s, '&' => "&amp;", '<' => "&lt;", '>' => "&gt;", '"' => "&quot;")

"""
    to_html(deck::Deck; width="100%", height="500px", bundle=:cdn, title="DeckGL", scripts=String[]) -> String
    to_html(io::IO, deck::Deck; kwargs...)

Render `deck` as a complete HTML page. The `IO` form streams it out rather than building
it in memory first.

### Keyword Arguments
- `width`, `height`: CSS sizes for the container
- `bundle`: where deck.gl itself comes from.
  `:cdn` links unpkg, keeping the page small but requiring network access to view.
  `:local` inlines the bundle from the `deckgl` artifact, producing a page that
  renders offline. A `map_style` needs the network either way, for MapLibre and
  for the map tiles, as do the peer libraries described below.
- `title`: the page `<title>`
- `scripts`: URLs of extra scripts to load before deck.gl. The library the H3 layers need
  is added automatically (see `DeckGL.peer_scripts`); this is for anything else, such as
  a loader for `Tile3DLayer`.
"""
function to_html(io::IO, deck::Deck; width::AbstractString="100%", height::AbstractString="500px",
                 bundle::Symbol=:cdn, title::AbstractString="DeckGL", scripts = String[])
    print(io, replace(TEMPLATE_HEAD,
        "{{TITLE}}" => escape_html(title),
        "{{ASSETS}}" => asset_tags(deck, bundle, scripts),
        "{{WIDTH}}" => width,
        "{{HEIGHT}}" => height,
    ))
    to_js(io, deck)
    print(io, TEMPLATE_TAIL)
    return nothing
end

to_html(deck::Deck; kwargs...) = sprint(io -> to_html(io, deck; kwargs...))

"""
    save_html(deck::Deck, path; kwargs...) -> path

Write `deck` to an HTML file. Takes the same keyword arguments as `to_html`;
pass `bundle=:local` for a file that renders without network access.
"""
function save_html(deck::Deck, path::AbstractString; kwargs...)
    open(io -> to_html(io, deck; kwargs...), path, "w")
    return path
end

"""
    open_html(deck::Deck; kwargs...) -> path

Write `deck` to a temporary file and open it in the default browser. Takes the same
keyword arguments as `to_html`.
"""
function open_html(deck::Deck; kwargs...)
    path = save_html(deck, tempname() * ".html"; kwargs...)
    if Sys.isapple()
        run(`open $path`)
    elseif Sys.islinux()
        run(`xdg-open $path`)
    elseif Sys.iswindows()
        run(`cmd /c start $path`)
    else
        error("Don't know how to open a browser on this platform; the file is at $path")
    end
    return path
end
