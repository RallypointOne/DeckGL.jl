#-----------------------------------------------------------------------------# Convenience Functions
# High-level API for quick visualizations

# Mean of a set of longitudes/latitudes, falling back to (0, 0) for empty data
mean_lnglat(lngs, lats) =
    isempty(lngs) ? (0.0, 0.0) : (sum(lngs) / length(lngs), sum(lats) / length(lats))

# Center of the view, from two coordinate columns
function center_lnglat(data, lng::Symbol, lat::Symbol)
    cols = Tables.columns(data)
    mean_lnglat(Tables.getcolumn(cols, lng), Tables.getcolumn(cols, lat))
end

# Position accessors that name two columns can be centred directly; anything else
# (a single column of coordinate pairs, a GeoJSON blob) has no cheap centre.
center_lnglat(data, cols::AbstractVector{Symbol}) = center_lnglat(data, cols[1], cols[2])
center_lnglat(::Any, ::Any) = (0.0, 0.0)

# Every one of these functions ends the same way: one layer, centred on its own data.
centered(layer, center, zoom; kw...) =
    Deck(layer; initial_view_state = ViewState(; longitude = center[1], latitude = center[2], zoom, kw...))

# Center of the view, from one representative vertex per geometry.
# `vertex` returns `nothing` for geometries that have no usable vertex.
function center_lnglat(data, geom_col::Symbol, vertex)
    pts = [v for v in (vertex(g) for g in Tables.getcolumn(Tables.columns(data), geom_col)) if v !== nothing]
    mean_lnglat([p[1] for p in pts], [p[2] for p in pts])
end

"""
    scatter(data, lng, lat; radius=1, color=[255, 140, 0], opacity=1, zoom=10, kwargs...)

Create a scatterplot visualization.

### Arguments
- `data`: Tables.jl-compatible data source
- `lng`: Column name for longitude (Symbol)
- `lat`: Column name for latitude (Symbol)

### Keyword Arguments
- `radius`: Point radius (number or column Symbol). Default: `1`
- `color`: Point color as `[R,G,B]` or `[R,G,B,A]`. Default: `[255, 140, 0]`
- `opacity`: Layer opacity (0-1). Default: `1`
- `zoom`: Initial zoom level. Default: `10`
- `kwargs...`: Additional keyword arguments passed to `ScatterplotLayer`

### Example
```julia
data = (lng = [-122.4, -122.5], lat = [37.8, 37.7], size = [100, 200])
scatter(data, :lng, :lat, radius=:size, color=[0, 128, 255])
```
"""
function scatter(data, lng::Symbol, lat::Symbol;
    radius = 1,
    color = [255, 140, 0],
    opacity = 1.0,
    zoom = 10,
    kwargs...
)
    center = center_lnglat(data, lng, lat)

    layer = ScatterplotLayer(;
        data = data,
        get_position = [lng, lat],
        get_radius = radius,
        get_fill_color = color,
        opacity = opacity,
        kwargs...
    )

    centered(layer, center, zoom)
end

"""
    arcs(data, source, target; width=1, source_color=[0, 128, 255], target_color=[255, 0, 128], kwargs...)

Create an arc diagram visualization.

### Arguments
- `data`: Tables.jl-compatible data source
- `source`: Source position as `[lng_col, lat_col]` or single column Symbol
- `target`: Target position as `[lng_col, lat_col]` or single column Symbol

### Keyword Arguments
- `width`: Arc width (number or column Symbol). Default: `1`
- `source_color`: Source end color. Default: `[0, 128, 255]`
- `target_color`: Target end color. Default: `[255, 0, 128]`
- `opacity`: Layer opacity (0-1). Default: `1`
- `zoom`: Initial zoom level. Default: `3`
- `kwargs...`: Additional keyword arguments passed to `ArcLayer`

### Example
```julia
trips = (src_lng=[-122.4], src_lat=[37.8], dst_lng=[-73.9], dst_lat=[40.7])
arcs(trips, [:src_lng, :src_lat], [:dst_lng, :dst_lat])
```
"""
function arcs(data, source, target;
    width = 1,
    source_color = [0, 128, 255],
    target_color = [255, 0, 128],
    opacity = 1.0,
    zoom = 3,
    kwargs...
)
    center = center_lnglat(data, source)

    layer = ArcLayer(;
        data = data,
        get_source_position = source,
        get_target_position = target,
        get_width = width,
        get_source_color = source_color,
        get_target_color = target_color,
        opacity = opacity,
        kwargs...
    )

    centered(layer, center, zoom)
end

"""
    lines(data, source, target; width=1, color=[0, 0, 0], kwargs...)

Create a line visualization connecting points.

### Arguments
- `data`: Tables.jl-compatible data source
- `source`: Source position as `[lng_col, lat_col]`
- `target`: Target position as `[lng_col, lat_col]`

### Keyword Arguments
- `width`: Line width. Default: `1`
- `color`: Line color. Default: `[0, 0, 0]`
- `opacity`: Layer opacity (0-1). Default: `1`
- `zoom`: Initial zoom level. Default: `10`
- `kwargs...`: Additional keyword arguments passed to `LineLayer`
"""
function lines(data, source, target;
    width = 1,
    color = [0, 0, 0],
    opacity = 1.0,
    zoom = 10,
    kwargs...
)
    center = center_lnglat(data, source)

    layer = LineLayer(;
        data = data,
        get_source_position = source,
        get_target_position = target,
        get_width = width,
        get_color = color,
        opacity = opacity,
        kwargs...
    )

    centered(layer, center, zoom)
end

"""
    paths(data, path_col; width=1, color=[0, 0, 0], kwargs...)

Create a path visualization.

### Arguments
- `data`: Tables.jl-compatible data source
- `path_col`: Column containing path coordinates (arrays of [lng, lat] pairs)

### Keyword Arguments
- `width`: Path width. Default: `1`
- `color`: Path color. Default: `[0, 0, 0]`
- `opacity`: Layer opacity (0-1). Default: `1`
- `zoom`: Initial zoom level. Default: `10`
- `rounded`: Round line caps and joints. Default: `false`
- `kwargs...`: Additional keyword arguments passed to `PathLayer`
"""
function paths(data, path_col::Symbol;
    width = 1,
    color = [0, 0, 0],
    opacity = 1.0,
    zoom = 10,
    rounded = false,
    kwargs...
)
    # Center on the first point of each path
    center = center_lnglat(data, path_col, p -> isempty(p) ? nothing : first(p))

    layer = PathLayer(;
        data = data,
        get_path = path_col,
        get_width = width,
        get_color = color,
        opacity = opacity,
        cap_rounded = rounded,
        joint_rounded = rounded,
        kwargs...
    )

    centered(layer, center, zoom)
end

"""
    polygons(data, polygon_col; fill_color=[0, 0, 0, 100], line_color=[0, 0, 0], kwargs...)

Create a polygon visualization.

### Arguments
- `data`: Tables.jl-compatible data source
- `polygon_col`: Column containing polygon coordinates

### Keyword Arguments
- `fill_color`: Fill color. Default: `[0, 0, 0, 100]`
- `line_color`: Outline color. Default: `[0, 0, 0]`
- `line_width`: Outline width. Default: `1`
- `opacity`: Layer opacity (0-1). Default: `1`
- `zoom`: Initial zoom level. Default: `10`
- `kwargs...`: Additional keyword arguments passed to `PolygonLayer`
"""
function polygons(data, polygon_col::Symbol;
    fill_color = [0, 0, 0, 100],
    line_color = [0, 0, 0],
    line_width = 1,
    opacity = 1.0,
    zoom = 10,
    kwargs...
)
    # Center on the first vertex of each polygon's outer ring
    center = center_lnglat(data, polygon_col,
        p -> isempty(p) || isempty(first(p)) ? nothing : first(first(p)))

    layer = PolygonLayer(;
        data = data,
        get_polygon = polygon_col,
        get_fill_color = fill_color,
        get_line_color = line_color,
        get_line_width = line_width,
        opacity = opacity,
        kwargs...
    )

    centered(layer, center, zoom)
end

"""
    text(data, lng, lat, text_col; size=16, color=[0, 0, 0], kwargs...)

Create a text label visualization.

### Arguments
- `data`: Tables.jl-compatible data source
- `lng`: Column name for longitude
- `lat`: Column name for latitude
- `text_col`: Column containing text labels

### Keyword Arguments
- `size`: Text size. Default: `16`
- `color`: Text color. Default: `[0, 0, 0]`
- `opacity`: Layer opacity (0-1). Default: `1`
- `zoom`: Initial zoom level. Default: `10`
- `kwargs...`: Additional keyword arguments passed to `TextLayer`
"""
function text(data, lng::Symbol, lat::Symbol, text_col::Symbol;
    size = 16,
    color = [0, 0, 0],
    opacity = 1.0,
    zoom = 10,
    kwargs...
)
    center = center_lnglat(data, lng, lat)

    layer = TextLayer(;
        data = data,
        get_position = [lng, lat],
        get_text = text_col,
        get_size = size,
        get_color = color,
        opacity = opacity,
        kwargs...
    )

    centered(layer, center, zoom)
end

"""
    hexbin(data, lng, lat; radius=1000, elevation_weight=1, kwargs...)

Create a hexagonal binning visualization.

### Arguments
- `data`: Tables.jl-compatible data source
- `lng`: Column name for longitude
- `lat`: Column name for latitude

### Keyword Arguments
- `radius`: Hexagon radius in meters. Default: `1000`
- `elevation_weight`: Column for elevation weighting or constant. Default: `1`
- `color_weight`: Column for color weighting or constant. Default: `1`
- `elevation_scale`: Elevation multiplier. Default: `1`
- `extruded`: Render as 3D hexagons. Default: `true`
- `opacity`: Layer opacity (0-1). Default: `1`
- `zoom`: Initial zoom level. Default: `10`
- `kwargs...`: Additional keyword arguments passed to `HexagonLayer`
"""
function hexbin(data, lng::Symbol, lat::Symbol;
    radius = 1000,
    elevation_weight = 1,
    color_weight = 1,
    elevation_scale = 1,
    extruded = true,
    opacity = 1.0,
    zoom = 10,
    kwargs...
)
    center = center_lnglat(data, lng, lat)

    layer = HexagonLayer(;
        data = data,
        get_position = [lng, lat],
        radius = radius,
        get_elevation_weight = elevation_weight,
        get_color_weight = color_weight,
        elevation_scale = elevation_scale,
        extruded = extruded,
        opacity = opacity,
        kwargs...
    )

    centered(layer, center, zoom; pitch = extruded ? 45 : 0)
end

"""
    heatmap(data, lng, lat; radius=30, intensity=1, weight=1, kwargs...)

Create a heatmap visualization.

### Arguments
- `data`: Tables.jl-compatible data source
- `lng`: Column name for longitude
- `lat`: Column name for latitude

### Keyword Arguments
- `radius`: Radius of influence in pixels. Default: `30`
- `intensity`: Intensity multiplier. Default: `1`
- `weight`: Column for point weighting or constant. Default: `1`
- `threshold`: Minimum density threshold. Default: `0.05`
- `opacity`: Layer opacity (0-1). Default: `1`
- `zoom`: Initial zoom level. Default: `10`
- `kwargs...`: Additional keyword arguments passed to `HeatmapLayer`
"""
function heatmap(data, lng::Symbol, lat::Symbol;
    radius = 30,
    intensity = 1,
    weight = 1,
    threshold = 0.05,
    opacity = 1.0,
    zoom = 10,
    kwargs...
)
    center = center_lnglat(data, lng, lat)

    layer = HeatmapLayer(;
        data = data,
        get_position = [lng, lat],
        radius_pixels = radius,
        intensity = intensity,
        get_weight = weight,
        threshold = threshold,
        opacity = opacity,
        kwargs...
    )

    centered(layer, center, zoom)
end

"""
    geojson(data; fill_color=[0, 0, 0, 100], line_color=[0, 0, 0], kwargs...)

Create a GeoJSON visualization.

### Arguments
- `data`: GeoJSON data as Dict, JSON string, or URL

### Keyword Arguments
- `fill_color`: Fill color for polygons. Default: `[0, 0, 0, 100]`
- `line_color`: Line/stroke color. Default: `[0, 0, 0]`
- `line_width`: Line width. Default: `1`
- `point_radius`: Point radius. Default: `1`
- `opacity`: Layer opacity (0-1). Default: `1`
- `zoom`: Initial zoom level. Default: `4`
- `kwargs...`: Additional keyword arguments passed to `GeoJsonLayer`
"""
function geojson(data;
    fill_color = [0, 0, 0, 100],
    line_color = [0, 0, 0],
    line_width = 1,
    point_radius = 1,
    opacity = 1.0,
    zoom = 4,
    kwargs...
)
    layer = GeoJsonLayer(;
        data = data,
        get_fill_color = fill_color,
        get_line_color = line_color,
        get_line_width = line_width,
        get_point_radius = point_radius,
        opacity = opacity,
        kwargs...
    )

    Deck(layer, initial_view_state = ViewState(zoom = zoom))
end
