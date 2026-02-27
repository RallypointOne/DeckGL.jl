# UK Road Accidents — Personal injury accidents aggregated into a 3D grid
# Data: UK Department for Transport via deck.gl-data (Open Government Licence)
using DeckGL, Downloads

#--------------------------------------------------------------------------------# Download accident location data (~140K lng,lat pairs)
url = "https://raw.githubusercontent.com/visgl/deck.gl-data/master/examples/3d-heatmap/heatmap-data.csv"
lines = readlines(Downloads.download(url))

lngs = Float64[]
lats = Float64[]
for i in 2:length(lines)
    parts = split(lines[i], ',')
    length(parts) >= 2 || continue
    lng = tryparse(Float64, parts[1])
    lat = tryparse(Float64, parts[2])
    (lng === nothing || lat === nothing) && continue
    push!(lngs, lng)
    push!(lats, lat)
end

data = (lng = lngs, lat = lats)

#--------------------------------------------------------------------------------# Layers
grid = GridLayer(
    data = data,
    get_position = [:lng, :lat],
    cell_size = 200,
    elevation_scale = 8,
    extruded = true,
    coverage = 0.9,
    color_range = [
        [255, 255, 204],
        [199, 233, 180],
        [127, 205, 187],
        [65, 182, 196],
        [44, 127, 184],
        [37, 52, 148],
    ],
    opacity = 0.8,
)

#--------------------------------------------------------------------------------# Display
deck = Deck(
    [grid],
    initial_view_state = ViewState(longitude = -0.12, latitude = 51.51, zoom = 11.5, pitch = 45.0, bearing = -15.0),
    map_style = "https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json",
)
open_html(deck; height = "100vh")
