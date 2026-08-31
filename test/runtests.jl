using DeckGL
using DeckGL: JS, js, camelcase, to_color, is_color_prop, attribute_eltype, pack_columns, resolve_data, tooltip_table,
              typename, props, accessors, LAYER_NAMES, LAYER_PROPS, LAYER_ACCESSORS,
              LAYER_DOCS, WIDGET_NAMES, VIEW_NAMES, AGGREGATION_LAYERS, DECKGL_VERSION
using Base64: base64decode
using Test

# A weak dependency; loading it here activates the extension under test.
using Colors

const TBL = (lng = [-122.4, -122.5, -122.3],
             lat = [37.8, 37.7, 37.9],
             mag = [1.0, 2.0, 3.0],
             name = ["a", "b", "c"],
             pos = [(-122.4, 37.8), (-122.5, 37.7), (-122.3, 37.9)],
             path = [[[0.0, 0.0], [1.0, 1.0]], [[2.0, 2.0], [3.0, 3.0]], [[4.0, 4.0], [5.0, 5.0]]])

# Pull a base64 buffer back out of emitted JavaScript.
function decode_buffer(code::AbstractString, prop::Symbol, ::Type{T}) where {T}
    m = match(Regex("$prop:\\{value:DG\\.(?:f32|u8)\\(\"([^\"]*)\"\\),size:(\\d+)"), code)
    m === nothing && return nothing
    return reinterpret(T, base64decode(m[1])), parse(Int, m[2])
end

#-----------------------------------------------------------------------------# Metadata
@testset "metadata" begin
    @test !isempty(LAYER_NAMES)
    @test :ScatterplotLayer in LAYER_NAMES
    for name in LAYER_NAMES
        @test haskey(LAYER_PROPS, name)
        @test haskey(LAYER_ACCESSORS, name)
        @test haskey(LAYER_DOCS, name)
        @test :data in LAYER_PROPS[name]
        @test LAYER_ACCESSORS[name] ⊆ LAYER_PROPS[name]
        @test startswith(LAYER_DOCS[name], "https://deck.gl/")
    end
    @test :tooltip in props(ScatterplotLayer)          # `props` is the authoritative list
    @test :tooltip in DeckGL.EXTRA_LAYER_PROPS
    @test AGGREGATION_LAYERS ⊆ Set(LAYER_NAMES)
    @test :HexagonLayer in AGGREGATION_LAYERS
    @test !(:ScatterplotLayer in AGGREGATION_LAYERS)

    # Every generated name is bound and is the type it claims to be.
    for name in LAYER_NAMES
        @test typename(getfield(DeckGL, name)) === name
    end
    for name in WIDGET_NAMES
        @test typename(getfield(DeckGL, name)) === name
    end
    for name in VIEW_NAMES
        @test typename(getfield(DeckGL, name)) === name
    end
end

#-----------------------------------------------------------------------------# Prop names
@testset "prop names" begin
    @test camelcase(:get_position) === :getPosition
    @test camelcase(:radius_min_pixels) === :radiusMinPixels
    @test camelcase(:getPosition) === :getPosition
    @test camelcase(:id) === :id
    @test camelcase(:_normalize) === :_normalize      # deck.gl's own internal props
    @test camelcase(:_data_diff) === :_dataDiff

    layer = ScatterplotLayer(data = TBL, get_position = [:lng, :lat], radiusMinPixels = 3)
    @test haskey(layer, :get_position)
    @test haskey(layer, :radius_min_pixels)
    @test layer[:radius_min_pixels] == 3

    # `nothing` means "unset", so deck.gl applies its own default rather than one of ours.
    @test !haskey(ScatterplotLayer(data = TBL, get_radius = nothing), :get_radius)

    @test_logs (:warn, r"Unrecognized layer prop") ScatterplotLayer(data = TBL, get_positon = :lng)
    @test_logs ScatterplotLayer(data = TBL, get_position = [:lng, :lat])   # no warning
    @test_logs OrthographicView(controller = true)                        # views have no prop table
end

#-----------------------------------------------------------------------------# Colors
@testset "colors" begin
    @test to_color("#ff8800") == [255, 136, 0]
    @test to_color("ff8800") == [255, 136, 0]
    @test to_color("#ff8800cc") == [255, 136, 0, 204]
    @test to_color([255, 0, 0]) == [255, 0, 0]
    @test to_color([[255, 0, 0], [0, 0, 255]]) == [[255, 0, 0], [0, 0, 255]]
    @test to_color(:column) === :column          # a column reference is not a color

    @test is_color_prop(:ScatterplotLayer, :getFillColor)
    @test is_color_prop(:HexagonLayer, :colorRange)
    # These carry numbers. Rounding them into bytes would quietly ruin an aggregation.
    @test !is_color_prop(:HexagonLayer, :getColorWeight)
    @test !is_color_prop(:HexagonLayer, :getColorValue)
    @test !is_color_prop(:HexagonLayer, :colorDomain)
    @test attribute_eltype(:ScatterplotLayer, :getFillColor) === UInt8
    @test attribute_eltype(:HexagonLayer, :getColorWeight) === Float32

    # `color` is RGB(A) on TerrainLayer and a CSS string on the widgets, so the answer
    # is per class rather than per name.
    @test is_color_prop(:TerrainLayer, :color)
    @test !is_color_prop(:IconWidget, :color)
    @test !is_color_prop(:ToggleWidget, :onColor)
    @test ToggleWidget(color = "red")[:color] == "red"
    @test IconWidget(color = "#ff8800")[:color] == "#ff8800"
    @test TerrainLayer(color = "#ff8800")[:color] == [255, 136, 0]
    @test_throws ArgumentError to_color("#fff")

    @test ScatterplotLayer(data = TBL, get_fill_color = "#ff8800")[:get_fill_color] == [255, 136, 0]
    # Only color props are converted.
    @test ScatterplotLayer(data = TBL, line_width_units = "pixels")[:line_width_units] == "pixels"
end

#-----------------------------------------------------------------------------# Packing
@testset "pack_columns" begin
    @test pack_columns([[1.0, 2.0, 3.0]], Float32) == (Float32[1, 2, 3], 1)
    @test pack_columns([[1.0, 2.0], [3.0, 4.0]], Float32) == (Float32[1, 3, 2, 4], 2)
    @test pack_columns([[(1.0, 2.0), (3.0, 4.0)]], Float32) == (Float32[1, 2, 3, 4], 2)
    @test pack_columns([[[1, 2, 3], [4, 5, 6]]], UInt8) == (UInt8[1, 2, 3, 4, 5, 6], 3)

    # Strings and ragged values cannot be packed.
    @test pack_columns([["a", "b"]], Float32) === nothing
    @test pack_columns([[[1.0], [2.0, 3.0]]], Float32) === nothing
    @test pack_columns([[[[1.0, 2.0]], [[3.0, 4.0]]]], Float32) === nothing

    # Missing data is not numeric, so it falls back rather than throwing.
    @test pack_columns([[1.0, missing]], Float32) === nothing

    # Colors are clamped into a byte rather than erroring.
    @test pack_columns([[-5.0, 300.0]], UInt8) == (UInt8[0, 255], 1)
end

#-----------------------------------------------------------------------------# Data resolution
@testset "resolve_data" begin
    layer = ScatterplotLayer(data = TBL, get_position = [:lng, :lat], get_radius = :mag)
    resolved = resolve_data(layer)
    @test resolved.istable
    @test resolved.nrows == 3
    @test :getPosition in resolved.packed
    @test :getRadius in resolved.packed
    @test isempty(resolved.overrides)
    @test Set(a.prop for a in resolved.attributes) == Set([:getPosition, :getRadius])

    code = DeckGL.to_js(Deck(layer))
    values, size = decode_buffer(code, :getPosition, Float32)
    @test size == 2
    @test values ≈ Float32[-122.4, 37.8, -122.5, 37.7, -122.3, 37.9]

    # A single column of coordinate pairs packs the same way as two columns.
    @test decode_buffer(DeckGL.to_js(Deck(ScatterplotLayer(data = TBL, get_position = :pos))),
                        :getPosition, Float32)[2] == 2

    # Colors declare their normalization so deck.gl does not have to guess.
    coloured = DeckGL.to_js(Deck(ScatterplotLayer(data = TBL, get_position = [:lng, :lat],
                                                  get_fill_color = [:mag, :mag, :mag])))
    @test occursin("getFillColor:{value:DG.u8(", coloured)
    @test occursin("normalized:true", coloured)

    # Unpackable columns are served from a column by index instead.
    text = resolve_data(TextLayer(data = TBL, get_position = [:lng, :lat], get_text = :name))
    @test :getText in keys(text.overrides)
    @test occursin("o.index", text.overrides[:getText])
    @test any(startswith(name, "c_getText") for (name, _) in text.locals)

    # A weight is a number even though its name mentions colour.
    weights = DeckGL.to_js(Deck(HexagonLayer(data = TBL, get_position = [:lng, :lat],
                                             get_color_weight = :mag)))
    @test occursin("c_getColorWeight = DG.f32(", weights)

    # Aggregation layers cannot read binary attributes; they get indices instead.
    hexagon = resolve_data(HexagonLayer(data = TBL, get_position = [:lng, :lat]))
    @test hexagon.aggregating
    @test isempty(hexagon.packed)
    @test occursin("DG.at(", hexagon.overrides[:getPosition])
    @test occursin("DG.range(3)", DeckGL.to_js(Deck(HexagonLayer(data = TBL, get_position = [:lng, :lat]))))

    # `GeoJsonLayer` data is GeoJSON even when it satisfies Tables.jl, so it is never
    # packed -- GeoJSON.jl's `FeatureCollection` is a table, and binary attributes would
    # silently render nothing.
    feature_table = (geometry = ["a", "b"], pop = [10, 20])
    @test !resolve_data(GeoJsonLayer(data = feature_table)).istable
    @test !occursin("attributes:{}", DeckGL.to_js(Deck(GeoJsonLayer(data = feature_table))))
    @test occursin("\"pop\":[10,20]", DeckGL.to_js(Deck(GeoJsonLayer(data = feature_table))))
    # Other layers still pack a table.
    @test resolve_data(ScatterplotLayer(data = TBL, get_position = [:lng, :lat])).istable

    # Non-tables pass through untouched.
    geo = Dict("type" => "FeatureCollection", "features" => [])
    @test !resolve_data(GeoJsonLayer(data = geo)).istable
    @test occursin("FeatureCollection", DeckGL.to_js(Deck(GeoJsonLayer(data = geo))))
    @test occursin("\"https://example.com/x.geojson\"",
                   DeckGL.to_js(Deck(GeoJsonLayer(data = "https://example.com/x.geojson"))))

    @test_throws ArgumentError DeckGL.to_js(Deck(ScatterplotLayer(data = TBL, get_position = [:nope, :lat])))

    empty_layer = resolve_data(ScatterplotLayer(data = (lng = Float64[], lat = Float64[]),
                                                get_position = [:lng, :lat]))
    @test empty_layer.nrows == 0
end

#-----------------------------------------------------------------------------# JavaScript
@testset "js" begin
    @test js(1) == "1"
    @test js(1.5) == "1.5"
    @test js(Float32(1.5)) == "1.5"          # `1.5f0` is not valid JavaScript
    @test js(true) == "true"
    @test js(nothing) == "null"
    @test js(missing) == "null"
    @test js(Inf) == "Infinity"
    @test js(-Inf) == "-Infinity"
    @test js(NaN) == "NaN"
    @test js("hi") == "\"hi\""
    @test js([1, 2, 3]) == "[1,2,3]"
    @test js(JS("d => d.x")) == "d => d.x"
    @test js([JS("a"), 1]) == "[a,1]"
    @test js((a = 1, b = "x")) == "{\"a\":1,\"b\":\"x\"}"

    # Object keys are sorted so the same value always produces the same page.
    @test js(Dict(:b => 1, :a => 2)) == "{\"a\":2,\"b\":1}"
end

#-----------------------------------------------------------------------------# Deck
@testset "Deck" begin
    layer = ScatterplotLayer(data = TBL, get_position = [:lng, :lat])
    deck = Deck(layer)
    @test length(deck.layers) == 1
    @test Deck([layer, layer]).layers |> length == 2

    code = DeckGL.to_js(deck)
    @test occursin("new deck.ScatterplotLayer(", code)
    @test occursin("DG.mount(", code)

    # Ids are positional, so identical code makes an identical page in any session.
    two = DeckGL.to_js(Deck([layer, layer]))
    @test occursin("\"ScatterplotLayer-1\"", two)
    @test occursin("\"ScatterplotLayer-2\"", two)
    @test DeckGL.to_js(Deck([layer, layer])) == two
    @test occursin("\"custom\"", DeckGL.to_js(Deck(ScatterplotLayer(data = TBL, id = "custom",
                                                                    get_position = [:lng, :lat]))))

    widgets = DeckGL.to_js(Deck(layer, widgets = [ZoomWidget(placement = "top-left")]))
    @test occursin("new deck.ZoomWidget({placement:\"top-left\"})", widgets)

    views = DeckGL.to_js(Deck(layer, views = [OrthographicView(id = "ortho")]))
    @test occursin("new deck.OrthographicView(", views)

    # Extra Deck props pass through.
    @test occursin("onClick:info => 1", DeckGL.to_js(Deck(layer, on_click = JS("info => 1"))))

    # MapView cannot place a camera without a longitude and latitude, so a view state
    # that omits them gets the origin. A custom view is positioned differently and is
    # left alone.
    @test Deck(layer, initial_view_state = ViewState(zoom = 10)).initial_view_state[:longitude] == 0.0
    @test !haskey(Deck(layer, initial_view_state = ViewState(target = [0, 0, 0], zoom = 1),
                       views = [OrthographicView()]).initial_view_state, :longitude)

    vs = ViewState(longitude = -122.4, latitude = 37.8, zoom = 11)
    @test vs[:longitude] == -122.4
    @test occursin("\"zoom\":11", DeckGL.to_js(Deck(layer, initial_view_state = vs)))
end

#-----------------------------------------------------------------------------# Tooltips
@testset "tooltips" begin
    # Asking for a tooltip is asking for picking.
    @test ScatterplotLayer(data = TBL, get_position = [:lng, :lat], tooltip = true)[:pickable] == true
    @test ScatterplotLayer(data = TBL, get_position = [:lng, :lat], tooltip = true,
                           pickable = false)[:pickable] == false

    table = DeckGL.to_js(Deck(ScatterplotLayer(data = TBL, get_position = [:lng, :lat], tooltip = [:name])))
    @test occursin("keys:[\"name\"]", table)
    @test occursin("\"a\"", table)

    @test resolve_data(ScatterplotLayer(data = TBL, get_position = [:lng, :lat])).tooltip === nothing

    # Numeric tooltip columns ride the same typed-array transport as the attributes.
    @test occursin("cols:[DG.f32(", DeckGL.to_js(Deck(ScatterplotLayer(data = TBL,
        get_position = [:lng, :lat], tooltip = [:mag]))))

    # Picking an aggregation layer selects a bin, which describes itself.
    @test occursin("{object:true}", DeckGL.to_js(Deck(HexagonLayer(data = TBL,
        get_position = [:lng, :lat], tooltip = true))))

    code = DeckGL.to_js(Deck(ScatterplotLayer(data = TBL, get_position = [:lng, :lat], tooltip = [:name])))
    @test occursin("getTooltip:DG.tooltip(", code)
    # `tooltip` is ours, not deck.gl's, and must not reach the page.
    @test !occursin("tooltip:true", code)
end

#-----------------------------------------------------------------------------# HTML
@testset "html" begin
    deck = Deck(ScatterplotLayer(data = TBL, get_position = [:lng, :lat]))

    html = to_html(deck)
    @test occursin("<!DOCTYPE html>", html)
    @test occursin("unpkg.com/deck.gl@$DECKGL_VERSION", html)
    @test occursin("500px", html)
    @test !occursin("{{", html)

    @test occursin("300px", to_html(deck; height = "300px"))
    @test_throws ArgumentError to_html(deck; bundle = :nonsense)

    # A basemap pulls in MapLibre; without one it is never fetched.
    @test !occursin(DeckGL.CDN_MAPLIBRE_JS, html)
    @test occursin(DeckGL.CDN_MAPLIBRE_JS,
                   to_html(Deck(ScatterplotLayer(data = TBL, get_position = [:lng, :lat]),
                                map_style = "https://example.com/style.json")))

    # Widget CSS is only fetched when there are widgets.
    @test occursin("stylesheet", to_html(Deck(ScatterplotLayer(data = TBL, get_position = [:lng, :lat]),
                                              widgets = [ZoomWidget()])))

    # Data must not be able to close the script block early.
    hostile = Deck(TextLayer(data = (lng = [1.0], lat = [2.0], t = ["</script><b>x"]),
                             get_position = [:lng, :lat], get_text = :t))
    @test !occursin("</script><b>", to_html(hostile))
    @test occursin("<\\/script>", to_html(hostile))

    path = save_html(deck, tempname() * ".html")
    @test isfile(path)
    @test read(path, String) == to_html(deck)
end

#-----------------------------------------------------------------------------# Display
@testset "display" begin
    layer = ScatterplotLayer(data = TBL, get_position = [:lng, :lat])
    @test occursin("ScatterplotLayer", sprint(show, layer))
    @test occursin("3 rows", sprint(show, layer))
    @test occursin("Deck", sprint(show, Deck(layer)))
    @test occursin("ScatterplotLayer", sprint(show, MIME"text/plain"(), Deck(layer)))
    @test occursin("<iframe", sprint(show, MIME"text/html"(), Deck(layer)))
    @test occursin("ZoomWidget", sprint(show, ZoomWidget()))
    @test occursin("ViewState", sprint(show, ViewState(zoom = 3)))
end

#-----------------------------------------------------------------------------# Convenience
@testset "convenience" begin
    @test DeckGL.scatter(TBL, :lng, :lat) isa Deck
    @test DeckGL.arcs(TBL, [:lng, :lat], [:lng, :lat]) isa Deck
    @test DeckGL.lines(TBL, [:lng, :lat], [:lng, :lat]) isa Deck
    @test DeckGL.paths(TBL, :path) isa Deck
    @test DeckGL.text(TBL, :lng, :lat, :name) isa Deck
    @test DeckGL.hexbin(TBL, :lng, :lat) isa Deck
    @test DeckGL.heatmap(TBL, :lng, :lat) isa Deck
    @test DeckGL.geojson(Dict("type" => "FeatureCollection", "features" => [])) isa Deck

    # The view centres on the data.
    deck = DeckGL.scatter(TBL, :lng, :lat)
    @test deck.initial_view_state[:longitude] ≈ -122.4
    @test deck.initial_view_state[:latitude] ≈ 37.8

    # Every one of them produces a page.
    for d in (DeckGL.scatter(TBL, :lng, :lat), DeckGL.hexbin(TBL, :lng, :lat))
        @test occursin("DG.mount(", DeckGL.to_js(d))
    end
end

#-----------------------------------------------------------------------------# Extensions
@testset "Colors extension" begin
    @test to_color(colorant"red") == [255, 0, 0, 255]
    @test to_color(RGBA(0, 0, 1, 0.5))[1:3] == [0, 0, 255]
    @test ScatterplotLayer(data = TBL, get_fill_color = colorant"red")[:get_fill_color] ==
          [255, 0, 0, 255]
    @test HexagonLayer(data = TBL, color_range = [colorant"red", colorant"blue"])[:color_range] ==
          [[255, 0, 0, 255], [0, 0, 255, 255]]
end


#-----------------------------------------------------------------------------# Docs
# The layer list is generated from deck.gl, so a version bump can add layers. This keeps
# the documentation from silently falling behind them.
@testset "docs cover every layer" begin
    page = joinpath(dirname(@__DIR__), "docs", "layers.qmd")
    if isfile(page)
        text = read(page, String)
        undocumented = [n for n in LAYER_NAMES if !occursin("### $n", text)]
        @test isempty(undocumented)
    end
end

@testset "docs cover every widget" begin
    page = joinpath(dirname(@__DIR__), "docs", "widgets.qmd")
    if isfile(page)
        text = read(page, String)
        undocumented = [n for n in WIDGET_NAMES if !occursin("### $n", text)]
        @test isempty(undocumented)
    end
end

#-----------------------------------------------------------------------------# Browser
# Renders every layer type in headless Chrome. Opt in with DECKGL_BROWSER_TESTS=1 and a
# puppeteer install on NODE_PATH; asserting on emitted JavaScript cannot tell whether
# deck.gl actually draws anything.
if get(ENV, "DECKGL_BROWSER_TESTS", "0") == "1"
    @testset "browser" begin
        dir = mktempdir()
        run(`$(Base.julia_cmd()) --project=$(dirname(@__DIR__)) $(joinpath(@__DIR__, "browser", "make_pages.jl")) $dir`)
        pages = filter(endswith(".html"), readdir(dir; join = true))
        @test !isempty(pages)
        # `success` runs the command and reports the exit status instead of throwing.
        @test success(`node $(joinpath(@__DIR__, "browser", "verify.js")) $pages`)
    end
end
