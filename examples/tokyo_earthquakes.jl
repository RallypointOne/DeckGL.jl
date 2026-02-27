# Tokyo Region Earthquakes — Seismic activity near Tokyo from USGS catalog
# Data: USGS Earthquake Hazards Program (public domain)
using DeckGL, Downloads, JSON3

#--------------------------------------------------------------------------------# Fetch earthquake data from USGS (Tokyo region, 2020-2024, M1.5+)
url = string(
    "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson",
    "&starttime=2020-01-01&endtime=2024-12-31",
    "&minlatitude=34.5&maxlatitude=36.5",
    "&minlongitude=138.5&maxlongitude=141.0",
    "&minmagnitude=1.5&limit=5000",
)
response = JSON3.read(read(Downloads.download(url), String))
features = response[:features]

data = (
    lng = Float64[f[:geometry][:coordinates][1] for f in features],
    lat = Float64[f[:geometry][:coordinates][2] for f in features],
)

#--------------------------------------------------------------------------------# Layers
hexagons = HexagonLayer(
    data = data,
    get_position = [:lng, :lat],
    radius = 3000,
    elevation_scale = 50,
    extruded = true,
    coverage = 0.88,
    color_range = [
        [255, 255, 178],
        [254, 204, 92],
        [253, 141, 60],
        [240, 59, 32],
        [189, 0, 38],
        [128, 0, 38],
    ],
    opacity = 0.85,
)

#--------------------------------------------------------------------------------# Display
deck = Deck(
    [hexagons],
    initial_view_state = ViewState(longitude = 139.9, latitude = 35.4, zoom = 8.0, pitch = 50.0, bearing = -20.0),
    map_style = "https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json",
)
open_html(deck; height = "100vh")
