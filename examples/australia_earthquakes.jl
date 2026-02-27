# Australia / Indo-Pacific Earthquakes — Seismic activity from USGS catalog
# Data: USGS Earthquake Hazards Program (public domain)
using DeckGL, Downloads, JSON3

#--------------------------------------------------------------------------------# Fetch earthquake data from USGS (Indo-Pacific region, 2024, M4.5+)
url = string(
    "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson",
    "&starttime=2024-01-01&endtime=2024-12-31",
    "&minlatitude=-50&maxlatitude=10",
    "&minlongitude=95&maxlongitude=180",
    "&minmagnitude=4.5&limit=5000",
)
response = JSON3.read(read(Downloads.download(url), String))
features = response[:features]

lngs = Float64[f[:geometry][:coordinates][1] for f in features]
lats = Float64[f[:geometry][:coordinates][2] for f in features]
mags = Float64[something(f[:properties][:mag], 4.5) for f in features]

# Color by magnitude: green (low) → yellow → red (high)
colors = map(mags) do mag
    t = clamp((mag - 4.5) / 3.0, 0.0, 1.0)
    r = t < 0.5 ? round(Int, 255 * 2t) : 255
    g = t < 0.5 ? 220 : round(Int, 220 * (1 - 2(t - 0.5)))
    [r, g, 30, round(Int, 120 + 135 * t)]
end

quakes = (lng = lngs, lat = lats, magnitude = mags, color = colors)

# Monitoring station arcs (major seismograph cities → regional hotspots)
stations = (
    src_lng = [151.21, 151.21, 174.78, 174.78, 106.85],
    src_lat = [-33.87, -33.87, -41.29, -41.29,  -6.21],
    tgt_lng = [147.0,  155.0,  178.0,  167.0,  125.0],
    tgt_lat = [ -6.0,   -7.0,  -18.0,  -15.0,  -10.0],
)

#--------------------------------------------------------------------------------# Layers
scatter = ScatterplotLayer(
    data = quakes,
    get_position = [:lng, :lat],
    get_fill_color = :color,
    get_radius = :magnitude,
    radius_scale = 12000,
    radius_min_pixels = 2,
    radius_max_pixels = 25,
    opacity = 0.75,
)

hexbins = HexagonLayer(
    data = quakes,
    get_position = [:lng, :lat],
    radius = 50000,
    extruded = true,
    elevation_scale = 500,
    coverage = 0.85,
    opacity = 0.4,
)

arcs = ArcLayer(
    data = stations,
    get_source_position = [:src_lng, :src_lat],
    get_target_position = [:tgt_lng, :tgt_lat],
    get_source_color = [0, 200, 255, 180],
    get_target_color = [255, 100, 50, 180],
    get_width = 1.5,
    great_circle = true,
)

#--------------------------------------------------------------------------------# Display
deck = Deck(
    [hexbins, scatter, arcs],
    initial_view_state = ViewState(longitude = 145.0, latitude = -20.0, zoom = 3.5, pitch = 30.0, bearing = 10.0),
    map_style = "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json",
)
open_html(deck; height = "100vh")
