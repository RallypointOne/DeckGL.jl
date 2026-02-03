#-----------------------------------------------------------------------------# GeoInterface Integration
# Convert GeoInterface.jl geometries to GeoJSON format for deck.gl

import GeoInterface as GI

"""
    to_geojson(geom) -> Dict

Convert a GeoInterface-compatible geometry to a GeoJSON Dict.
"""
function to_geojson(geom)
    geom_type = GI.geomtrait(geom)
    to_geojson(geom_type, geom)
end

# Point
function to_geojson(::GI.PointTrait, geom)
    Dict{String,Any}(
        "type" => "Point",
        "coordinates" => [GI.x(geom), GI.y(geom)]
    )
end

# MultiPoint
function to_geojson(::GI.MultiPointTrait, geom)
    coords = [[GI.x(p), GI.y(p)] for p in GI.getpoint(geom)]
    Dict{String,Any}(
        "type" => "MultiPoint",
        "coordinates" => coords
    )
end

# LineString
function to_geojson(::GI.LineStringTrait, geom)
    coords = [[GI.x(p), GI.y(p)] for p in GI.getpoint(geom)]
    Dict{String,Any}(
        "type" => "LineString",
        "coordinates" => coords
    )
end

# MultiLineString
function to_geojson(::GI.MultiLineStringTrait, geom)
    coords = [[[GI.x(p), GI.y(p)] for p in GI.getpoint(line)] for line in GI.getgeom(geom)]
    Dict{String,Any}(
        "type" => "MultiLineString",
        "coordinates" => coords
    )
end

# Polygon (with potential holes)
function to_geojson(::GI.PolygonTrait, geom)
    rings = []
    for ring in GI.getring(geom)
        push!(rings, [[GI.x(p), GI.y(p)] for p in GI.getpoint(ring)])
    end
    Dict{String,Any}(
        "type" => "Polygon",
        "coordinates" => rings
    )
end

# MultiPolygon
function to_geojson(::GI.MultiPolygonTrait, geom)
    polygons = []
    for poly in GI.getgeom(geom)
        rings = []
        for ring in GI.getring(poly)
            push!(rings, [[GI.x(p), GI.y(p)] for p in GI.getpoint(ring)])
        end
        push!(polygons, rings)
    end
    Dict{String,Any}(
        "type" => "MultiPolygon",
        "coordinates" => polygons
    )
end

# GeometryCollection
function to_geojson(::GI.GeometryCollectionTrait, geom)
    geometries = [to_geojson(g) for g in GI.getgeom(geom)]
    Dict{String,Any}(
        "type" => "GeometryCollection",
        "geometries" => geometries
    )
end

# Feature
function to_geojson(::GI.FeatureTrait, feature)
    Dict{String,Any}(
        "type" => "Feature",
        "geometry" => to_geojson(GI.geometry(feature)),
        "properties" => Dict(GI.properties(feature))
    )
end

# FeatureCollection
function to_geojson(::GI.FeatureCollectionTrait, fc)
    features = [to_geojson(f) for f in GI.getfeature(fc)]
    Dict{String,Any}(
        "type" => "FeatureCollection",
        "features" => features
    )
end

"""
    geojson_layer(geom; kwargs...) -> GeoJsonLayer

Create a GeoJsonLayer from any GeoInterface-compatible geometry.

# Example
```julia
using Shapefile

shp = Shapefile.Table("boundaries.shp")
layer = geojson_layer(shp, get_fill_color=[255, 0, 0, 100])
```
"""
function geojson_layer(geom; kwargs...)
    geojson = to_geojson(geom)
    GeoJsonLayer(; data=geojson, kwargs...)
end
