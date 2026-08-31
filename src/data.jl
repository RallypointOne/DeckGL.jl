#-----------------------------------------------------------------------------# Column accessors
# An accessor prop names data columns when it is given as a `Symbol` or a list of them.
# Any other value -- a number, an RGBA vector, a `JS` function -- is a constant and is
# sent through as-is.
column_names(v::Symbol) = Symbol[v]
column_names(v::AbstractVector{Symbol}) = collect(v)
column_names(::Any) = nothing

# deck.gl keeps colors as unsigned bytes and every other attribute as 32-bit floats.
attribute_eltype(class::Symbol, prop::Symbol) = is_color_prop(class, prop) ? UInt8 : Float32

to_element(::Type{UInt8}, x::Real) = round(UInt8, clamp(x, 0, 255))
to_element(::Type{Float32}, x::Real) = Float32(x)

"""
    DeckGL.pack_columns(columns, E) -> (Vector{E}, size) or nothing

Interleave `columns` into the single flat buffer deck.gl uploads to the GPU, or return
`nothing` when the values are not fixed-width numbers and the accessor has to stay a
JavaScript function.

One numeric column packs at `size` 1 and several interleave at `size` = however many;
both are the same loop. A single column of equal-length numeric tuples or vectors packs
at `size` = that length. A column of variable-length paths or of strings does not pack.
"""
function pack_columns(columns::Vector, ::Type{E}) where {E<:Number}
    n = length(first(columns))
    ncol = length(columns)

    # A column whose elements are themselves coordinates, e.g. one column of `(lng, lat)`.
    if ncol == 1
        element = eltype(only(columns))
        if element <: Union{Tuple,AbstractVector}
            eltype(element) <: Real || return nothing
            return pack_vectors(only(columns), E, n)
        end
    end

    all(c -> eltype(c) <: Real, columns) || return nothing
    buffer = Vector{E}(undef, n * ncol)
    i = 0
    for row in 1:n, c in columns
        @inbounds buffer[i += 1] = to_element(E, c[row])
    end
    return buffer, ncol
end

function pack_vectors(column, ::Type{E}, n::Int) where {E<:Number}
    n == 0 && return E[], 1
    width = length(first(column))
    buffer = Vector{E}(undef, n * width)
    i = 0
    for v in column
        # Ragged values cannot be a fixed-width attribute. Checked here rather than in a
        # prior pass so the column is walked once.
        length(v) == width || return nothing
        for x in v
            @inbounds buffer[i += 1] = to_element(E, x)
        end
    end
    return buffer, width
end

#-----------------------------------------------------------------------------# Resolving a layer's data
# A packed accessor, held as the buffer itself so it can be base64-encoded straight into
# the page rather than through an intermediate string.
struct Attribute
    prop::Symbol
    buffer::Vector
    size::Int
end

# Everything the emitter needs to write one layer: how `data` should be expressed, the
# accessor props that became JavaScript, the local `const`s those accessors close over,
# and the columns a tooltip would show.
struct LayerData
    istable::Bool
    passthrough::Any                    # non-table `data`, written as-is
    nrows::Int
    aggregating::Bool
    attributes::Vector{Attribute}
    packed::Set{Symbol}
    overrides::Dict{Symbol,String}
    locals::Vector{Pair{String,Any}}
    tooltip::Union{Nothing,Pair{Vector{String},Vector{Any}}}
end

LayerData(passthrough) = LayerData(false, passthrough, 0, false, Attribute[], Set{Symbol}(),
                                   Dict{Symbol,String}(), Pair{String,Any}[], nothing)

"""
    DeckGL.resolve_data(layer) -> LayerData

Turn a layer's `data` and its column-referencing accessors into the form deck.gl reads
fastest, given what the layer does with them.

Most layers upload their accessors straight to the GPU, so a table becomes deck.gl's
binary form, `{length, attributes}`: each accessor that resolves to fixed-width numeric
columns is packed into one typed array and handed over whole. That skips both the
per-row objects Julia would otherwise allocate and the per-row accessor calls deck.gl
would otherwise make.

Aggregation layers bin their records before drawing anything and read every one through
its accessor, so binary attributes are silently ignored -- a `HexagonLayer` given them
produces a single bin. Those layers get an index array for `data` and accessors that
read the same packed buffers by index, which keeps the compact transport while feeding
the aggregator what it needs.

Accessors that cannot be packed -- strings, variable-length paths -- ship as a plain
column and are read by index either way. deck.gl walks a placeholder of `length`
entries for binary data, so those accessors still receive the right index even though
there are no row objects to pass them.

Anything that is not a table (GeoJSON, a URL) is passed through untouched, as is
anything given to `GeoJsonLayer`, whose data is GeoJSON however Tables.jl sees it.
"""
function resolve_data(layer::Layer)
    data = get(layer.props, :data, nothing)
    class = typename(layer)
    # deck.gl types `GeoJsonLayer`'s data as GeoJSON, never as a table of records. A
    # GeoJSON value can still satisfy Tables.jl -- GeoJSON.jl's `FeatureCollection` does
    # -- so which path to take is decided by the layer, not by the data.
    (data === nothing || class === :GeoJsonLayer || !Tables.istable(data)) &&
        return LayerData(data)

    cols = Tables.columns(data)
    available = Set(Tables.columnnames(cols))
    nrows = Tables.rowcount(cols)
    aggregating = class in AGGREGATION_LAYERS

    attributes = Attribute[]
    packed = Set{Symbol}()
    overrides = Dict{Symbol,String}()
    locals = Pair{String,Any}[]

    for prop in accessors(layer)
        haskey(layer.props, prop) || continue
        names = column_names(layer.props[prop])
        names === nothing && continue
        absent = filter(nm -> !(nm in available), names)
        isempty(absent) ||
            throw(ArgumentError("$class prop `$prop` names column(s) $(absent) not found in `data`"))

        columns = [Tables.getcolumn(cols, nm) for nm in names]
        buffer = pack_columns(columns, attribute_eltype(class, prop))
        name = "c_$prop"

        if buffer === nothing
            push!(locals, name => (length(columns) == 1 ? only(columns) : collect(zip(columns...))))
            overrides[prop] = aggregating ? "d => $name[d]" : "(_, o) => $name[o.index]"
        elseif aggregating
            push!(locals, name => first(buffer))
            overrides[prop] = "DG.at($name, $(last(buffer)))"
        else
            push!(attributes, Attribute(prop, first(buffer), last(buffer)))
            push!(packed, prop)
        end
    end

    return LayerData(true, nothing, nrows, aggregating, attributes, packed, overrides,
                     locals, tooltip_columns(layer, cols))
end

#-----------------------------------------------------------------------------# Tooltips
# Binary data has no row objects, so picking reports an index and nothing else. The
# columns a tooltip needs travel separately and are looked up by that index. Numeric ones
# ride the same typed-array transport as the attributes rather than going out as JSON.
tooltip_names(spec::Bool, available) = spec ? collect(available) : nothing
tooltip_names(spec::AbstractVector{Symbol}, available) = collect(spec)

function tooltip_columns(layer::Layer, cols)
    spec = get(layer.props, :tooltip, nothing)
    spec === nothing && return nothing
    # Picking an aggregation layer selects a bin rather than a source row, so the bin's
    # own summary -- its count and aggregated values -- is what there is to show.
    typename(layer) in AGGREGATION_LAYERS && return String[] => Any[]

    names = tooltip_names(spec, Tables.columnnames(cols))
    (names === nothing || isempty(names)) && return nothing

    values = Any[]
    for nm in names
        column = Tables.getcolumn(cols, nm)
        buffer = pack_columns([column], Float32)
        push!(values, buffer !== nothing && last(buffer) == 1 ? first(buffer) : column)
    end
    return String.(names) => values
end
