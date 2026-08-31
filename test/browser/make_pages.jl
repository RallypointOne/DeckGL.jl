# Generate one page per layer type for `test/browser/verify.js` to render.
#
#   julia --project test/browser/make_pages.jl <output-dir>
#
# Pages inline the deck.gl bundle so the check exercises the artifact and needs no
# network. A page named `*.nopick.html` renders through a framebuffer rather than
# pickable geometry, so the harness only requires it to mount without errors.

using DeckGL

outdir = isempty(ARGS) ? mktempdir() : ARGS[1]
mkpath(outdir)

n = 200
lng = -122.4 .+ 0.2 .* randn(n)
lat = 37.8 .+ 0.2 .* randn(n)
tbl = (; lng, lat,
    lng2 = lng .+ 0.1, lat2 = lat .+ 0.1,
    weight = abs.(randn(n)),
    label = ["p$i" for i in 1:n],
    position = collect(zip(lng, lat)),
    color = [[255, 140, 0, 200] for _ in 1:n],
    path = [[[lng[i], lat[i]], [lng[i] + 0.05, lat[i] + 0.05], [lng[i] + 0.1, lat[i]]] for i in 1:n],
    polygon = [[[lng[i], lat[i]], [lng[i] + 0.05, lat[i]], [lng[i] + 0.05, lat[i] + 0.05], [lng[i], lat[i]]] for i in 1:n],
    timestamps = [[0.0, 5.0, 10.0] for _ in 1:n],
)

view = ViewState(longitude = -122.4, latitude = 37.8, zoom = 9)
deck_of(layer; kw...) = Deck(layer; initial_view_state = view, kw...)

pages = Pair{String,Deck}[
    "scatterplot" => deck_of(ScatterplotLayer(data = tbl, get_position = [:lng, :lat],
        get_radius = :weight, radius_scale = 2000, radius_min_pixels = 3,
        get_fill_color = :color, pickable = true, tooltip = [:label, :weight])),
    "scatterplot-tuple-position" => deck_of(ScatterplotLayer(data = tbl, get_position = :position,
        get_radius = 2000, get_fill_color = "#ff8800cc", pickable = true)),
    "arc" => deck_of(ArcLayer(data = tbl, get_source_position = [:lng, :lat],
        get_target_position = [:lng2, :lat2], get_width = 3,
        get_source_color = [0, 128, 255], get_target_color = [255, 0, 128], pickable = true)),
    "line" => deck_of(LineLayer(data = tbl, get_source_position = [:lng, :lat],
        get_target_position = [:lng2, :lat2], get_width = 4, get_color = [0, 0, 0], pickable = true)),
    "path" => deck_of(PathLayer(data = tbl, get_path = :path, get_width = 50,
        get_color = [200, 0, 0], width_min_pixels = 3, pickable = true)),
    "polygon" => deck_of(PolygonLayer(data = tbl, get_polygon = :polygon,
        get_fill_color = [0, 100, 200, 160], get_line_color = [0, 0, 0], pickable = true)),
    "solid-polygon" => deck_of(SolidPolygonLayer(data = tbl, get_polygon = :polygon,
        get_fill_color = [0, 160, 100, 200], pickable = true)),
    "text" => deck_of(TextLayer(data = tbl, get_position = [:lng, :lat], get_text = :label,
        get_size = 18, get_color = [0, 0, 0], pickable = true)),
    "column" => deck_of(ColumnLayer(data = tbl, get_position = [:lng, :lat], radius = 800,
        get_elevation = :weight, elevation_scale = 2000, extruded = true,
        get_fill_color = [255, 140, 0], pickable = true)),
    "point-cloud" => deck_of(PointCloudLayer(data = tbl, get_position = [:lng, :lat],
        get_color = [80, 80, 255], point_size = 6, pickable = true)),
    "hexagon" => deck_of(HexagonLayer(data = tbl, get_position = [:lng, :lat], radius = 1500,
        get_elevation_weight = :weight, elevation_scale = 500, extruded = true, pickable = true)),
    "grid" => deck_of(GridLayer(data = tbl, get_position = [:lng, :lat], cell_size = 1500,
        get_color_weight = :weight, extruded = false, pickable = true)),
    "screen-grid" => deck_of(ScreenGridLayer(data = tbl, get_position = [:lng, :lat],
        get_weight = :weight, cell_size_pixels = 40, pickable = true)),
    "contour" => deck_of(ContourLayer(data = tbl, get_position = [:lng, :lat], cell_size = 1500,
        get_weight = :weight, pickable = true,
        contours = [Dict("threshold" => 1, "color" => [255, 0, 0], "strokeWidth" => 3)])),
    "trips" => deck_of(TripsLayer(data = tbl, get_path = :path, get_timestamps = :timestamps,
        get_color = [255, 0, 0], width_min_pixels = 4, current_time = 5, trail_length = 20,
        pickable = true)),
    "geojson" => deck_of(GeoJsonLayer(data = Dict(
            "type" => "FeatureCollection",
            "features" => [Dict("type" => "Feature",
                "geometry" => Dict("type" => "Polygon", "coordinates" => [[[-122.5, 37.7], [-122.3, 37.7], [-122.3, 37.9], [-122.5, 37.9], [-122.5, 37.7]]]),
                "properties" => Dict("name" => "box"))]),
        get_fill_color = [255, 0, 0, 120], get_line_color = [0, 0, 0], pickable = true)),
    "widgets" => deck_of(ScatterplotLayer(data = tbl, get_position = [:lng, :lat],
            get_radius = 2000, get_fill_color = [0, 0, 255], pickable = true);
        widgets = [ZoomWidget(), CompassWidget(), FullscreenWidget()]),
    "multi-layer" => deck_of([
        ScatterplotLayer(data = tbl, get_position = [:lng, :lat], get_radius = 1200,
            get_fill_color = [255, 0, 0, 150], pickable = true),
        TextLayer(data = tbl, get_position = [:lng, :lat], get_text = :label, get_size = 12,
            get_color = [0, 0, 0], pickable = true),
    ]),
    "js-accessor" => deck_of(ScatterplotLayer(data = tbl, get_position = [:lng, :lat],
        get_radius = JS("(_, o) => 500 + 20 * o.index"), get_fill_color = [0, 200, 0],
        pickable = true)),
    "orthographic" => Deck(
        ScatterplotLayer(data = (x = randn(n) .* 100, y = randn(n) .* 100),
            get_position = [:x, :y], get_radius = 8, get_fill_color = [200, 0, 200],
            pickable = true),
        initial_view_state = ViewState(target = [0, 0, 0], zoom = 1),
        views = [OrthographicView(controller = true)]),
]

# Heatmap renders into a texture, so there is no pickable geometry to hit.
nopick = Set(["heatmap"])
push!(pages, "heatmap" => deck_of(HeatmapLayer(data = tbl, get_position = [:lng, :lat],
    get_weight = :weight, radius_pixels = 40)))

# These reach the network: a basemap always does, and the CDN bundle is the point of
# that page. Opt in with DECKGL_ONLINE_PAGES=1.
cdn = Set{String}()
if get(ENV, "DECKGL_ONLINE_PAGES", "0") == "1"
    push!(pages, "basemap" => deck_of(ScatterplotLayer(data = tbl, get_position = [:lng, :lat],
            get_radius = 1500, get_fill_color = [255, 0, 0, 200], pickable = true);
        map_style = "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json"))
    push!(pages, "cdn-bundle" => deck_of(ScatterplotLayer(data = tbl, get_position = [:lng, :lat],
        get_radius = 1500, get_fill_color = [0, 0, 255], pickable = true)))
    push!(cdn, "cdn-bundle")
end

paths = String[]
for (name, deck) in pages
    file = joinpath(outdir, name in nopick ? "$name.nopick.html" : "$name.html")
    save_html(deck, file; bundle = name in cdn ? :cdn : :local, width = "800px", height = "600px")
    push!(paths, file)
end

println(outdir)
foreach(println, paths)
