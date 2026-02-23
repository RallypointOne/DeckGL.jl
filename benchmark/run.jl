using BenchmarkTools, JSON3, Dates
using DeckGL

#--------------------------------------------------------------------------------# Benchmark Suite
#--------------------------------------------------------------------------------
suite = BenchmarkGroup()

suite["layer_creation"] = BenchmarkGroup()
suite["layer_creation"]["ScatterplotLayer"] = @benchmarkable ScatterplotLayer(
    data = data,
    get_position = [:lng, :lat],
    get_radius = 100,
) setup=(data = (lng = randn(100), lat = randn(100)))
suite["layer_creation"]["ArcLayer"] = @benchmarkable ArcLayer(
    data = data,
    get_source_position = [:src_lng, :src_lat],
    get_target_position = [:dst_lng, :dst_lat],
) setup=(data = (src_lng = randn(100), src_lat = randn(100), dst_lng = randn(100), dst_lat = randn(100)))

suite["json"] = BenchmarkGroup()
suite["json"]["to_json_small"] = @benchmarkable to_json(deck) setup=(
    data = (lng = randn(10), lat = randn(10));
    layer = ScatterplotLayer(data=data, get_position=[:lng, :lat]);
    deck = Deck(layer))
suite["json"]["to_json_medium"] = @benchmarkable to_json(deck) setup=(
    data = (lng = randn(1000), lat = randn(1000));
    layer = ScatterplotLayer(data=data, get_position=[:lng, :lat]);
    deck = Deck(layer))

suite["html"] = BenchmarkGroup()
suite["html"]["to_html"] = @benchmarkable to_html(deck) setup=(
    data = (lng = randn(100), lat = randn(100));
    layer = ScatterplotLayer(data=data, get_position=[:lng, :lat]);
    deck = Deck(layer))

#--------------------------------------------------------------------------------# Run Benchmarks
#--------------------------------------------------------------------------------
println("Running benchmarks...")
results = run(suite, verbose=true)

#--------------------------------------------------------------------------------# Collect Results
#--------------------------------------------------------------------------------
function collect_results(group::BenchmarkGroup, prefix="")
    entries = []
    for (key, val) in group
        name = isempty(prefix) ? string(key) : "$prefix/$key"
        if val isa BenchmarkGroup
            append!(entries, collect_results(val, name))
        else
            t = median(val)
            push!(entries, (;
                name,
                time_ns = t.time,
                memory_bytes = t.memory,
                allocs = t.allocs,
            ))
        end
    end
    return entries
end

benchmarks = collect_results(results)

output = (;
    julia_version = string(VERSION),
    cpu = Sys.cpu_info()[1].model,
    timestamp = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SSZ"),
    benchmarks,
)

outfile = joinpath(@__DIR__, "results.json")
open(outfile, "w") do io
    JSON3.pretty(io, output)
end

println("Results written to $outfile")
