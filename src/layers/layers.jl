# Include all layer definitions

# Core layers
include("scatterplot.jl")
include("arc.jl")
include("line.jl")
include("path.jl")
include("polygon.jl")
include("text.jl")

# Aggregation layers
include("hexagon.jl")
include("grid.jl")
include("heatmap.jl")

# Composite layers
include("geojson.jl")
