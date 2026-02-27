# US Fire Hotspots — Near real-time satellite fire detections from NASA FIRMS
# Data: NASA FIRMS VIIRS NOAA-20 (public domain) — updates every 60 minutes
using DeckGL, Downloads

#--------------------------------------------------------------------------------# Download 7-day VIIRS fire detections for the contiguous US
url = "https://firms.modaps.eosdis.nasa.gov/data/active_fire/noaa-20-viirs-c2/csv/J1_VIIRS_C2_USA_contiguous_and_Hawaii_7d.csv"
lines = readlines(Downloads.download(url))

# Parse CSV (columns: latitude, longitude, bright_ti4, scan, track, acq_date,
#   acq_time, satellite, confidence, version, bright_ti5, frp, daynight)
lngs = Float64[]
lats = Float64[]
frps = Float64[]  # Fire Radiative Power (MW)
for i in 2:length(lines)
    parts = split(lines[i], ',')
    length(parts) >= 12 || continue
    lat = parse(Float64, parts[1])
    lon = parse(Float64, parts[2])
    frp = tryparse(Float64, parts[12])
    push!(lats, lat)
    push!(lngs, lon)
    push!(frps, something(frp, 1.0))
end

data = (lng = lngs, lat = lats, frp = frps)

# City reference labels
cities = (
    lng  = [-118.24, -122.42, -104.99, -112.07, -97.74,  -84.39, -90.07],
    lat  = [  34.05,   37.77,   39.74,   33.45,  30.27,   33.75,  29.95],
    name = ["Los Angeles", "San Francisco", "Denver", "Phoenix", "Houston", "Atlanta", "New Orleans"],
)

#--------------------------------------------------------------------------------# Layers
heat = HeatmapLayer(
    data = data,
    get_position = [:lng, :lat],
    get_weight = :frp,
    radius_pixels = 20,
    intensity = 0.8,
    threshold = 0.03,
    color_range = [
        [255, 255, 200, 30],
        [255, 220, 80, 100],
        [255, 160, 20, 160],
        [240, 80, 0, 200],
        [200, 20, 0, 230],
        [120, 0, 0, 250],
    ],
    opacity = 0.75,
)

fire_scatter = ScatterplotLayer(
    data = data,
    get_position = [:lng, :lat],
    get_fill_color = [255, 80, 0, 80],
    get_radius = 2000,
    radius_min_pixels = 1,
    opacity = 0.4,
)

city_labels = TextLayer(
    data = cities,
    get_position = [:lng, :lat],
    get_text = :name,
    get_size = 12,
    get_color = [255, 255, 255, 230],
    background = true,
    get_background_color = [30, 30, 30, 190],
    background_padding = [5, 2, 5, 2],
    font_family = "Helvetica, Arial, sans-serif",
    font_weight = 700,
)

#--------------------------------------------------------------------------------# Display
deck = Deck(
    [heat, fire_scatter, city_labels],
    initial_view_state = ViewState(longitude = -98.0, latitude = 39.0, zoom = 4.0),
    map_style = "https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json",
)
open_html(deck; height = "100vh")
