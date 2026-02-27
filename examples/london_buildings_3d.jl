# London Buildings 3D — Real building footprints with heights from OpenStreetMap
# Data: OpenStreetMap via Overpass API (ODbL license)
using DeckGL, Downloads, JSON3

#--------------------------------------------------------------------------------# Fetch buildings with height tags in the City of London financial district
query = "[out:json];way[\"building\"][\"height\"](51.505,-0.095,51.52,-0.07);out%20geom;"
url = "https://overpass-api.de/api/interpreter?data=$(query)"
response = JSON3.read(read(Downloads.download(url), String))
elements = response[:elements]

# Extract polygon coordinates and height from each building
polygons = Vector{Vector{Vector{Float64}}}()
heights = Float64[]
colors = Vector{Int}[]

for elem in elements
    poly = [[Float64(pt[:lon]), Float64(pt[:lat])] for pt in elem[:geometry]]
    push!(polygons, poly)

    h_str = get(elem[:tags], :height, nothing)
    h = h_str !== nothing ? tryparse(Float64, replace(string(h_str), r"[^0-9.]" => "")) : nothing
    h = something(h, 15.0)
    push!(heights, h)

    # Color by height: short buildings are cool blue, tall buildings are warm
    t = clamp((h - 5) / 175, 0.0, 1.0)
    push!(colors, [round(Int, 40 + 215 * t), round(Int, 140 + 80 * (1 - t)), round(Int, 200 * (1 - t))])
end

buildings_data = (polygon = polygons, elevation = heights, color = colors)

#--------------------------------------------------------------------------------# Layers
polys = PolygonLayer(
    data = buildings_data,
    get_polygon = :polygon,
    get_fill_color = :color,
    get_elevation = :elevation,
    extruded = true,
    wireframe = true,
    get_line_color = [255, 255, 255, 80],
    elevation_scale = 1,
    opacity = 0.85,
)

#--------------------------------------------------------------------------------# Display
deck = Deck(
    [polys],
    initial_view_state = ViewState(longitude = -0.083, latitude = 51.513, zoom = 15.0, pitch = 55.0, bearing = 30.0),
    map_style = "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json",
)
open_html(deck; height = "100vh")
