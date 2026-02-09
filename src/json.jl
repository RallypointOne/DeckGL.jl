#-----------------------------------------------------------------------------# Data Conversion
# Convert Tables.jl-compatible data to array of row objects for deck.gl
function table_to_rows(data)
    Tables.istable(data) || error("Data must be Tables.jl compatible")
    rows = Tables.rowtable(data)
    # Use Dict{Symbol,Any} to allow adding computed fields like _position
    return [Dict{Symbol,Any}(pairs(row)) for row in rows]
end

#-----------------------------------------------------------------------------# Accessor Helpers
# Convert a value or symbol accessor to deck.gl format
accessor(val::Symbol) = "@@=$val"
accessor(val) = val

# Replace Inf with nothing (deck.gl doesn't handle Inf)
clamp_inf(x) = x == Inf ? nothing : x

# Filter out nothing values from a dict (deck.gl doesn't handle null)
filter_nothing(d::Dict) = Dict(k => v for (k, v) in d if v !== nothing)

# Handle position accessor from one or two columns
function process_position!(data_rows, pos::Vector{Symbol}, field::Symbol)
    col1, col2 = pos
    for row in data_rows
        row[field] = [row[col1], row[col2]]
    end
    return "@@=$field"
end
process_position!(data_rows, pos::Symbol, field::Symbol) = "@@=$pos"

#-----------------------------------------------------------------------------# Layer JSON
# Convert a layer to its deck.gl JSON specification
function layer_to_dict(layer::ScatterplotLayer)
    data_rows = table_to_rows(layer.data)

    get_position = process_position!(data_rows, layer.get_position, :_position)

    filter_nothing(Dict{String,Any}(
        "@@type" => layer_type(layer),
        "id" => layer.id,
        "data" => data_rows,
        "getPosition" => get_position,
        "getRadius" => accessor(layer.get_radius),
        "getFillColor" => accessor(layer.get_fill_color),
        "getLineColor" => accessor(layer.get_line_color),
        "getLineWidth" => accessor(layer.get_line_width),
        "radiusScale" => layer.radius_scale,
        "radiusMinPixels" => layer.radius_min_pixels,
        "radiusMaxPixels" => clamp_inf(layer.radius_max_pixels),
        "lineWidthUnits" => layer.line_width_units,
        "lineWidthScale" => layer.line_width_scale,
        "lineWidthMinPixels" => layer.line_width_min_pixels,
        "lineWidthMaxPixels" => clamp_inf(layer.line_width_max_pixels),
        "stroked" => layer.stroked,
        "filled" => layer.filled,
        "billboard" => layer.billboard,
        "opacity" => layer.opacity,
        "pickable" => layer.pickable,
        "visible" => layer.visible,
    ))
end

function layer_to_dict(layer::ArcLayer)
    data_rows = table_to_rows(layer.data)

    get_source_position = process_position!(data_rows, layer.get_source_position, :_sourcePosition)
    get_target_position = process_position!(data_rows, layer.get_target_position, :_targetPosition)

    filter_nothing(Dict{String,Any}(
        "@@type" => layer_type(layer),
        "id" => layer.id,
        "data" => data_rows,
        "getSourcePosition" => get_source_position,
        "getTargetPosition" => get_target_position,
        "getSourceColor" => accessor(layer.get_source_color),
        "getTargetColor" => accessor(layer.get_target_color),
        "getWidth" => accessor(layer.get_width),
        "getHeight" => accessor(layer.get_height),
        "getTilt" => accessor(layer.get_tilt),
        "greatCircle" => layer.great_circle,
        "widthUnits" => layer.width_units,
        "widthScale" => layer.width_scale,
        "widthMinPixels" => layer.width_min_pixels,
        "widthMaxPixels" => clamp_inf(layer.width_max_pixels),
        "opacity" => layer.opacity,
        "pickable" => layer.pickable,
        "visible" => layer.visible,
    ))
end

function layer_to_dict(layer::LineLayer)
    data_rows = table_to_rows(layer.data)

    get_source_position = process_position!(data_rows, layer.get_source_position, :_sourcePosition)
    get_target_position = process_position!(data_rows, layer.get_target_position, :_targetPosition)

    filter_nothing(Dict{String,Any}(
        "@@type" => layer_type(layer),
        "id" => layer.id,
        "data" => data_rows,
        "getSourcePosition" => get_source_position,
        "getTargetPosition" => get_target_position,
        "getColor" => accessor(layer.get_color),
        "getWidth" => accessor(layer.get_width),
        "widthUnits" => layer.width_units,
        "widthScale" => layer.width_scale,
        "widthMinPixels" => layer.width_min_pixels,
        "widthMaxPixels" => clamp_inf(layer.width_max_pixels),
        "opacity" => layer.opacity,
        "pickable" => layer.pickable,
        "visible" => layer.visible,
    ))
end

function layer_to_dict(layer::PathLayer)
    data_rows = table_to_rows(layer.data)

    filter_nothing(Dict{String,Any}(
        "@@type" => layer_type(layer),
        "id" => layer.id,
        "data" => data_rows,
        "getPath" => accessor(layer.get_path),
        "getColor" => accessor(layer.get_color),
        "getWidth" => accessor(layer.get_width),
        "widthUnits" => layer.width_units,
        "widthScale" => layer.width_scale,
        "widthMinPixels" => layer.width_min_pixels,
        "widthMaxPixels" => clamp_inf(layer.width_max_pixels),
        "capRounded" => layer.cap_rounded,
        "jointRounded" => layer.joint_rounded,
        "billboard" => layer.billboard,
        "miterLimit" => layer.miter_limit,
        "opacity" => layer.opacity,
        "pickable" => layer.pickable,
        "visible" => layer.visible,
    ))
end

function layer_to_dict(layer::PolygonLayer)
    data_rows = table_to_rows(layer.data)

    filter_nothing(Dict{String,Any}(
        "@@type" => layer_type(layer),
        "id" => layer.id,
        "data" => data_rows,
        "getPolygon" => accessor(layer.get_polygon),
        "filled" => layer.filled,
        "stroked" => layer.stroked,
        "extruded" => layer.extruded,
        "wireframe" => layer.wireframe,
        "elevationScale" => layer.elevation_scale,
        "getElevation" => accessor(layer.get_elevation),
        "getFillColor" => accessor(layer.get_fill_color),
        "getLineColor" => accessor(layer.get_line_color),
        "getLineWidth" => accessor(layer.get_line_width),
        "lineWidthUnits" => layer.line_width_units,
        "lineWidthScale" => layer.line_width_scale,
        "lineWidthMinPixels" => layer.line_width_min_pixels,
        "lineWidthMaxPixels" => clamp_inf(layer.line_width_max_pixels),
        "lineJointRounded" => layer.line_joint_rounded,
        "lineMiterLimit" => layer.line_miter_limit,
        "opacity" => layer.opacity,
        "pickable" => layer.pickable,
        "visible" => layer.visible,
    ))
end

function layer_to_dict(layer::TextLayer)
    data_rows = table_to_rows(layer.data)

    get_position = process_position!(data_rows, layer.get_position, :_position)

    filter_nothing(Dict{String,Any}(
        "@@type" => layer_type(layer),
        "id" => layer.id,
        "data" => data_rows,
        "getPosition" => get_position,
        "getText" => accessor(layer.get_text),
        "getSize" => accessor(layer.get_size),
        "getColor" => accessor(layer.get_color),
        "getAngle" => accessor(layer.get_angle),
        "getTextAnchor" => layer.get_text_anchor,
        "getAlignmentBaseline" => layer.get_alignment_baseline,
        "getPixelOffset" => layer.get_pixel_offset,
        "background" => layer.background,
        "getBackgroundColor" => accessor(layer.get_background_color),
        "backgroundPadding" => layer.background_padding,
        "fontFamily" => layer.font_family,
        "fontWeight" => layer.font_weight,
        "lineHeight" => layer.line_height,
        "billboard" => layer.billboard,
        "sizeScale" => layer.size_scale,
        "sizeUnits" => layer.size_units,
        "sizeMinPixels" => layer.size_min_pixels,
        "sizeMaxPixels" => clamp_inf(layer.size_max_pixels),
        "opacity" => layer.opacity,
        "pickable" => layer.pickable,
        "visible" => layer.visible,
    ))
end

function layer_to_dict(layer::HexagonLayer)
    data_rows = table_to_rows(layer.data)

    get_position = process_position!(data_rows, layer.get_position, :_position)

    filter_nothing(Dict{String,Any}(
        "@@type" => layer_type(layer),
        "id" => layer.id,
        "data" => data_rows,
        "getPosition" => get_position,
        "radius" => layer.radius,
        "coverage" => layer.coverage,
        "extruded" => layer.extruded,
        "elevationScale" => layer.elevation_scale,
        "elevationRange" => layer.elevation_range,
        "getColorWeight" => accessor(layer.get_color_weight),
        "getElevationWeight" => accessor(layer.get_elevation_weight),
        "colorAggregation" => layer.color_aggregation,
        "elevationAggregation" => layer.elevation_aggregation,
        "colorRange" => layer.color_range,
        "upperPercentile" => layer.upper_percentile,
        "lowerPercentile" => layer.lower_percentile,
        "opacity" => layer.opacity,
        "pickable" => layer.pickable,
        "visible" => layer.visible,
    ))
end

function layer_to_dict(layer::GridLayer)
    data_rows = table_to_rows(layer.data)

    get_position = process_position!(data_rows, layer.get_position, :_position)

    filter_nothing(Dict{String,Any}(
        "@@type" => layer_type(layer),
        "id" => layer.id,
        "data" => data_rows,
        "getPosition" => get_position,
        "cellSize" => layer.cell_size,
        "coverage" => layer.coverage,
        "extruded" => layer.extruded,
        "elevationScale" => layer.elevation_scale,
        "elevationRange" => layer.elevation_range,
        "getColorWeight" => accessor(layer.get_color_weight),
        "getElevationWeight" => accessor(layer.get_elevation_weight),
        "colorAggregation" => layer.color_aggregation,
        "elevationAggregation" => layer.elevation_aggregation,
        "colorRange" => layer.color_range,
        "upperPercentile" => layer.upper_percentile,
        "lowerPercentile" => layer.lower_percentile,
        "opacity" => layer.opacity,
        "pickable" => layer.pickable,
        "visible" => layer.visible,
    ))
end

function layer_to_dict(layer::HeatmapLayer)
    data_rows = table_to_rows(layer.data)

    get_position = process_position!(data_rows, layer.get_position, :_position)

    filter_nothing(Dict{String,Any}(
        "@@type" => layer_type(layer),
        "id" => layer.id,
        "data" => data_rows,
        "getPosition" => get_position,
        "radiusPixels" => layer.radius_pixels,
        "intensity" => layer.intensity,
        "threshold" => layer.threshold,
        "getWeight" => accessor(layer.get_weight),
        "colorRange" => layer.color_range,
        "aggregation" => layer.aggregation,
        "weightsTextureSize" => layer.weights_texture_size,
        "debounceTimeout" => layer.debounce_timeout,
        "opacity" => layer.opacity,
        "pickable" => layer.pickable,
        "visible" => layer.visible,
    ))
end

function layer_to_dict(layer::GeoJsonLayer)
    filter_nothing(Dict{String,Any}(
        "@@type" => layer_type(layer),
        "id" => layer.id,
        "data" => layer.data,
        "filled" => layer.filled,
        "stroked" => layer.stroked,
        "extruded" => layer.extruded,
        "wireframe" => layer.wireframe,
        "elevationScale" => layer.elevation_scale,
        "getElevation" => accessor(layer.get_elevation),
        "pointType" => layer.point_type,
        "getPointRadius" => accessor(layer.get_point_radius),
        "pointRadiusUnits" => layer.point_radius_units,
        "pointRadiusScale" => layer.point_radius_scale,
        "pointRadiusMinPixels" => layer.point_radius_min_pixels,
        "pointRadiusMaxPixels" => clamp_inf(layer.point_radius_max_pixels),
        "getLineWidth" => accessor(layer.get_line_width),
        "lineWidthUnits" => layer.line_width_units,
        "lineWidthScale" => layer.line_width_scale,
        "lineWidthMinPixels" => layer.line_width_min_pixels,
        "lineWidthMaxPixels" => clamp_inf(layer.line_width_max_pixels),
        "lineJointRounded" => layer.line_joint_rounded,
        "lineCapRounded" => layer.line_cap_rounded,
        "lineMiterLimit" => layer.line_miter_limit,
        "getFillColor" => accessor(layer.get_fill_color),
        "getLineColor" => accessor(layer.get_line_color),
        "opacity" => layer.opacity,
        "pickable" => layer.pickable,
        "visible" => layer.visible,
    ))
end

#-----------------------------------------------------------------------------# ViewState JSON
function viewstate_to_dict(vs::ViewState)
    Dict{String,Any}(
        "longitude" => vs.longitude,
        "latitude" => vs.latitude,
        "zoom" => vs.zoom,
        "pitch" => vs.pitch,
        "bearing" => vs.bearing,
    )
end

#-----------------------------------------------------------------------------# Deck JSON
function deck_to_dict(deck::Deck)
    spec = Dict{String,Any}(
        "initialViewState" => viewstate_to_dict(deck.initial_view_state),
        "controller" => deck.controller,
        "layers" => [layer_to_dict(layer) for layer in deck.layers],
    )

    if deck.map_style !== nothing
        spec["mapStyle"] = deck.map_style
    end

    return spec
end

"""
    to_json(deck::Deck) -> String

Convert a Deck to its deck.gl JSON specification string.
"""
function to_json(deck::Deck)
    spec = deck_to_dict(deck)
    return JSON3.write(spec)
end
