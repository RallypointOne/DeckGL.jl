using DeckGL
using Test

@testset "DeckGL.jl" begin
    @testset "ViewState" begin
        vs = ViewState()
        @test vs.longitude == 0.0
        @test vs.latitude == 0.0
        @test vs.zoom == 1.0
        @test vs.pitch == 0.0
        @test vs.bearing == 0.0

        vs2 = ViewState(longitude=-122.4, latitude=37.8, zoom=11)
        @test vs2.longitude == -122.4
        @test vs2.latitude == 37.8
        @test vs2.zoom == 11
    end

    @testset "ScatterplotLayer" begin
        data = (
            lng = [-122.4, -122.5, -122.3],
            lat = [37.8, 37.7, 37.9],
            value = [100, 200, 150]
        )

        layer = ScatterplotLayer(
            data = data,
            get_position = [:lng, :lat],
            get_radius = :value,
            get_fill_color = [255, 140, 0, 200]
        )

        @test layer.data == data
        @test layer.get_position == [:lng, :lat]
        @test layer.get_radius == :value
        @test layer.get_fill_color == [255, 140, 0, 200]
        @test layer.opacity == 1.0
        @test layer.pickable == false
    end

    @testset "ArcLayer" begin
        data = (
            src_lng = [-122.4, -122.5],
            src_lat = [37.8, 37.7],
            dst_lng = [-73.9, -87.6],
            dst_lat = [40.7, 41.9],
            count = [100, 50]
        )

        layer = ArcLayer(
            data = data,
            get_source_position = [:src_lng, :src_lat],
            get_target_position = [:dst_lng, :dst_lat],
            get_width = :count,
            get_source_color = [0, 128, 255],
            get_target_color = [255, 0, 128]
        )

        @test layer.get_source_position == [:src_lng, :src_lat]
        @test layer.get_target_position == [:dst_lng, :dst_lat]
        @test layer.get_width == :count
        @test layer.great_circle == false
    end

    @testset "LineLayer" begin
        data = (
            from_lng = [-122.4],
            from_lat = [37.8],
            to_lng = [-122.3],
            to_lat = [37.9]
        )

        layer = LineLayer(
            data = data,
            get_source_position = [:from_lng, :from_lat],
            get_target_position = [:to_lng, :to_lat],
            get_color = [255, 0, 0],
            get_width = 2
        )

        @test layer.get_color == [255, 0, 0]
        @test layer.get_width == 2
    end

    @testset "PathLayer" begin
        data = (
            path = [[[-122.4, 37.8], [-122.5, 37.7], [-122.3, 37.9]]],
            name = ["Route A"]
        )

        layer = PathLayer(
            data = data,
            get_path = :path,
            get_color = [0, 128, 255],
            get_width = 5,
            cap_rounded = true
        )

        @test layer.get_path == :path
        @test layer.cap_rounded == true
        @test layer.joint_rounded == false
    end

    @testset "PolygonLayer" begin
        data = (
            polygon = [[[[-122.4, 37.8], [-122.5, 37.7], [-122.3, 37.7], [-122.4, 37.8]]]],
            value = [100]
        )

        layer = PolygonLayer(
            data = data,
            get_polygon = :polygon,
            get_fill_color = [255, 140, 0, 100],
            extruded = true,
            get_elevation = :value
        )

        @test layer.get_polygon == :polygon
        @test layer.extruded == true
        @test layer.get_elevation == :value
        @test layer.filled == true
        @test layer.stroked == true
    end

    @testset "TextLayer" begin
        data = (
            lng = [-122.4, -73.9],
            lat = [37.8, 40.7],
            name = ["San Francisco", "New York"]
        )

        layer = TextLayer(
            data = data,
            get_position = [:lng, :lat],
            get_text = :name,
            get_size = 16,
            get_color = [0, 0, 0]
        )

        @test layer.get_text == :name
        @test layer.get_size == 16
        @test layer.billboard == true
    end

    @testset "Deck" begin
        data = (lng = [-122.4], lat = [37.8])
        layer = ScatterplotLayer(data=data, get_position=[:lng, :lat])

        deck = Deck(layer)
        @test length(deck.layers) == 1
        @test deck.controller == true
        @test deck.map_style === nothing

        deck2 = Deck(
            [layer],
            initial_view_state = ViewState(longitude=-122.4, latitude=37.8, zoom=11),
            controller = false
        )
        @test deck2.initial_view_state.longitude == -122.4
        @test deck2.controller == false
    end

    @testset "JSON serialization" begin
        # ScatterplotLayer
        data = (lng = [-122.4, -122.5], lat = [37.8, 37.7], size = [100, 200])
        layer = ScatterplotLayer(data=data, get_position=[:lng, :lat], get_radius=:size)
        deck = Deck(layer, initial_view_state=ViewState(longitude=-122.4, latitude=37.8, zoom=10))

        json_str = to_json(deck)
        @test occursin("ScatterplotLayer", json_str)
        @test occursin("-122.4", json_str)
        @test occursin("initialViewState", json_str)

        # ArcLayer
        arc_data = (src_lng=[-122.4], src_lat=[37.8], dst_lng=[-73.9], dst_lat=[40.7])
        arc_layer = ArcLayer(data=arc_data, get_source_position=[:src_lng, :src_lat], get_target_position=[:dst_lng, :dst_lat])
        arc_deck = Deck(arc_layer)
        arc_json = to_json(arc_deck)
        @test occursin("ArcLayer", arc_json)
        @test occursin("getSourcePosition", arc_json)
        @test occursin("getTargetPosition", arc_json)

        # LineLayer
        line_data = (from_lng=[-122.4], from_lat=[37.8], to_lng=[-122.3], to_lat=[37.9])
        line_layer = LineLayer(data=line_data, get_source_position=[:from_lng, :from_lat], get_target_position=[:to_lng, :to_lat])
        line_json = to_json(Deck(line_layer))
        @test occursin("LineLayer", line_json)

        # PathLayer
        path_data = (path=[[[-122.4, 37.8], [-122.5, 37.7]]],)
        path_layer = PathLayer(data=path_data, get_path=:path)
        path_json = to_json(Deck(path_layer))
        @test occursin("PathLayer", path_json)
        @test occursin("getPath", path_json)

        # PolygonLayer
        poly_data = (polygon=[[[[-122.4, 37.8], [-122.5, 37.7], [-122.3, 37.7]]]],)
        poly_layer = PolygonLayer(data=poly_data, get_polygon=:polygon)
        poly_json = to_json(Deck(poly_layer))
        @test occursin("PolygonLayer", poly_json)
        @test occursin("getPolygon", poly_json)

        # TextLayer
        text_data = (lng=[-122.4], lat=[37.8], name=["SF"])
        text_layer = TextLayer(data=text_data, get_position=[:lng, :lat], get_text=:name)
        text_json = to_json(Deck(text_layer))
        @test occursin("TextLayer", text_json)
        @test occursin("getText", text_json)
    end

    @testset "HTML rendering" begin
        data = (lng = [-122.4], lat = [37.8])
        layer = ScatterplotLayer(data=data, get_position=[:lng, :lat])
        deck = Deck(layer)

        html = to_html(deck)
        @test occursin("<!DOCTYPE html>", html)
        @test occursin("deck.gl", html)
        @test occursin("DeckGL", html)
    end

    @testset "Convenience functions" begin
        data = (
            lng = [-122.4, -122.5, -122.3],
            lat = [37.8, 37.7, 37.9],
            value = [100, 200, 150],
            name = ["A", "B", "C"]
        )

        # scatter
        deck1 = scatter(data, :lng, :lat, radius=:value)
        @test length(deck1.layers) == 1
        @test deck1.layers[1] isa ScatterplotLayer

        # text
        deck2 = text(data, :lng, :lat, :name, size=20)
        @test length(deck2.layers) == 1
        @test deck2.layers[1] isa TextLayer

        # arcs
        arc_data = (src_lng=[-122.4], src_lat=[37.8], dst_lng=[-73.9], dst_lat=[40.7])
        deck3 = arcs(arc_data, [:src_lng, :src_lat], [:dst_lng, :dst_lat])
        @test deck3.layers[1] isa ArcLayer

        # lines
        line_data = (from_lng=[-122.4], from_lat=[37.8], to_lng=[-122.3], to_lat=[37.9])
        deck4 = lines(line_data, [:from_lng, :from_lat], [:to_lng, :to_lat])
        @test deck4.layers[1] isa LineLayer

        # paths
        path_data = (path=[[[-122.4, 37.8], [-122.5, 37.7]]],)
        deck5 = paths(path_data, :path)
        @test deck5.layers[1] isa PathLayer

        # polygons
        poly_data = (polygon=[[[[-122.4, 37.8], [-122.5, 37.7], [-122.3, 37.7]]]],)
        deck6 = polygons(poly_data, :polygon)
        @test deck6.layers[1] isa PolygonLayer
    end

    @testset "Multiple layers" begin
        scatter_data = (lng=[-122.4], lat=[37.8])
        text_data = (lng=[-122.4], lat=[37.8], name=["Point"])

        layers = [
            ScatterplotLayer(data=scatter_data, get_position=[:lng, :lat]),
            TextLayer(data=text_data, get_position=[:lng, :lat], get_text=:name)
        ]

        deck = Deck(layers)
        @test length(deck.layers) == 2
        @test deck.layers[1] isa ScatterplotLayer
        @test deck.layers[2] isa TextLayer

        json_str = to_json(deck)
        @test occursin("ScatterplotLayer", json_str)
        @test occursin("TextLayer", json_str)
    end

    @testset "HexagonLayer" begin
        data = (
            lng = [-122.4, -122.5, -122.3, -122.45, -122.35],
            lat = [37.8, 37.7, 37.9, 37.75, 37.85],
            value = [100, 200, 150, 180, 120]
        )

        layer = HexagonLayer(
            data = data,
            get_position = [:lng, :lat],
            get_elevation_weight = :value,
            radius = 500,
            extruded = true
        )

        @test layer.radius == 500
        @test layer.extruded == true
        @test layer.get_elevation_weight == :value

        json_str = to_json(Deck(layer))
        @test occursin("HexagonLayer", json_str)
        @test occursin("radius", json_str)
    end

    @testset "GridLayer" begin
        data = (
            lng = [-122.4, -122.5, -122.3],
            lat = [37.8, 37.7, 37.9]
        )

        layer = GridLayer(
            data = data,
            get_position = [:lng, :lat],
            cell_size = 200,
            extruded = true
        )

        @test layer.cell_size == 200
        @test layer.extruded == true

        json_str = to_json(Deck(layer))
        @test occursin("GridLayer", json_str)
        @test occursin("cellSize", json_str)
    end

    @testset "HeatmapLayer" begin
        data = (
            lng = [-122.4, -122.5, -122.3],
            lat = [37.8, 37.7, 37.9],
            weight = [1, 2, 3]
        )

        layer = HeatmapLayer(
            data = data,
            get_position = [:lng, :lat],
            get_weight = :weight,
            radius_pixels = 50,
            intensity = 2
        )

        @test layer.radius_pixels == 50
        @test layer.intensity == 2
        @test layer.get_weight == :weight

        json_str = to_json(Deck(layer))
        @test occursin("HeatmapLayer", json_str)
        @test occursin("radiusPixels", json_str)
    end

    @testset "GeoJsonLayer" begin
        # GeoJSON as Dict
        geojson_data = Dict(
            "type" => "FeatureCollection",
            "features" => [
                Dict(
                    "type" => "Feature",
                    "geometry" => Dict(
                        "type" => "Point",
                        "coordinates" => [-122.4, 37.8]
                    ),
                    "properties" => Dict("name" => "SF")
                )
            ]
        )

        layer = GeoJsonLayer(
            data = geojson_data,
            get_fill_color = [255, 0, 0, 100],
            get_point_radius = 100
        )

        @test layer.data == geojson_data
        @test layer.get_fill_color == [255, 0, 0, 100]
        @test layer.filled == true
        @test layer.stroked == true

        json_str = to_json(Deck(layer))
        @test occursin("GeoJsonLayer", json_str)
        @test occursin("FeatureCollection", json_str)

        # GeoJSON as URL string
        layer_url = GeoJsonLayer(data = "https://example.com/data.geojson")
        @test layer_url.data == "https://example.com/data.geojson"
    end

    @testset "Phase 3 convenience functions" begin
        data = (
            lng = [-122.4, -122.5, -122.3],
            lat = [37.8, 37.7, 37.9],
            value = [100, 200, 150]
        )

        # hexbin
        deck1 = hexbin(data, :lng, :lat, radius=500)
        @test deck1.layers[1] isa HexagonLayer
        @test deck1.initial_view_state.pitch == 45  # extruded=true sets pitch

        # heatmap
        deck2 = heatmap(data, :lng, :lat, weight=:value)
        @test deck2.layers[1] isa HeatmapLayer

        # geojson
        geojson_data = Dict("type" => "FeatureCollection", "features" => [])
        deck3 = geojson(geojson_data)
        @test deck3.layers[1] isa GeoJsonLayer
    end

    @testset "Widgets" begin
        # Default construction
        zw = ZoomWidget()
        @test zw.id == "zoom"
        @test zw.placement == "top-right"
        @test zw.orientation == "vertical"
        @test zw.transition_duration == 200

        cw = CompassWidget()
        @test cw.id == "compass"
        @test cw.placement == "top-right"

        fw = FullscreenWidget()
        @test fw.id == "fullscreen"
        @test fw.placement == "top-right"

        # Custom construction
        zw2 = ZoomWidget(placement="top-left", orientation="horizontal")
        @test zw2.placement == "top-left"
        @test zw2.orientation == "horizontal"

        # Deck with widgets
        data = (lng = [-122.4], lat = [37.8])
        layer = ScatterplotLayer(data=data, get_position=[:lng, :lat])
        deck = Deck(layer, widgets=[ZoomWidget(), CompassWidget()])
        @test length(deck.widgets) == 2
        @test deck.widgets[1] isa ZoomWidget
        @test deck.widgets[2] isa CompassWidget

        # Deck without widgets (default)
        deck2 = Deck(layer)
        @test isempty(deck2.widgets)

        # JSON serialization with widgets
        json_str = to_json(deck)
        @test occursin("ZoomWidget", json_str)
        @test occursin("CompassWidget", json_str)
        @test occursin("transitionDuration", json_str)

        # JSON without widgets omits key
        json_str2 = to_json(deck2)
        @test !occursin("widgets", json_str2)
    end

    @testset "GeoInterface integration" begin
        using DeckGL: to_geojson, geojson_layer
        import GeoInterface as GI

        # Test point conversion
        point = (coords = [-122.4, 37.8],)
        GI.isgeometry(::typeof(point)) = true
        GI.geomtrait(::typeof(point)) = GI.PointTrait()
        GI.x(p::typeof(point)) = p.coords[1]
        GI.y(p::typeof(point)) = p.coords[2]

        geojson_point = to_geojson(point)
        @test geojson_point["type"] == "Point"
        @test geojson_point["coordinates"] == [-122.4, 37.8]
    end
end
