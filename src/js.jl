#-----------------------------------------------------------------------------# JS
"""
    JS(code::AbstractString)

Raw JavaScript, emitted verbatim into the generated page.  Escape hatch to provide 
functions (typical for deck.gl properties).

### Examples
```julia
# A prop deck.gl expects to be a function
ScatterplotLayer(data=df, get_position=[:lng, :lat], get_radius=JS("d => 10"))

# A callback
Deck(layer, on_click=JS("info => console.log(info.index)"))
```
"""
struct JS
    code::String
end

JS(x::JS) = x
Base.show(io::IO, x::JS) = print(io, "JS(", repr(x.code), ")")
Base.:(==)(a::JS, b::JS) = a.code == b.code

#-----------------------------------------------------------------------------# Emitting JavaScript
"""
    DeckGL.js(x) -> String

Render `x` as a JavaScript expression.

JSON is very nearly a subset of JavaScript, so plain data is emitted as JSON. The
differences this handles are `JS` values, which pass through untouched, and non-finite
numbers, which JSON cannot represent but JavaScript can.

Prefer `DeckGL.print_js` where the result is only going to be written out: the
emitters stream into an `IO` rather than building the page from intermediate strings.
"""
js(x) = sprint(print_js, x)

"""
    DeckGL.print_js(io, x)

Write `x` to `io` as a JavaScript expression. See `DeckGL.js`.
"""
print_js(io::IO, ::Nothing) = print(io, "null")
print_js(io::IO, ::Missing) = print(io, "null")

# `</` cannot appear inside a <script> element or it closes it early; `<\/` is a no-op in
# JavaScript strings and regular expressions alike. Applied to the two kinds of value
# that can contain those characters, rather than scanned over the finished page -- most
# of which is base64, whose alphabet has no `<`.
escape_script(s::AbstractString) = occursin("</", s) ? replace(s, "</" => "<\\/") : s

print_js(io::IO, x::JS) = print(io, escape_script(x.code))
print_js(io::IO, x::Symbol) = print_js(io, String(x))
print_js(io::IO, x::AbstractString) = print(io, escape_script(sprint(JSON.json, x)))

# JSON.jl writes every `Number` the way JavaScript spells it, including `Float32` (as the
# shortest round-tripping form rather than `1.0f0`) and, with `allownan`, the non-finite
# values JSON itself cannot represent.
print_js(io::IO, x::Number) = JSON.json(io, x; allownan = true)

function print_js(io::IO, x::Union{AbstractVector,Tuple})
    print(io, '[')
    for (i, v) in enumerate(x)
        i > 1 && print(io, ',')
        print_js(io, v)
    end
    print(io, ']')
end

function print_object(io::IO, pairs)
    print(io, '{')
    for (i, (k, v)) in enumerate(pairs)
        i > 1 && print(io, ',')
        print_js(io, string(k))
        print(io, ':')
        print_js(io, v)
    end
    print(io, '}')
end

# Keys are sorted so that the same Julia value always produces the same page. `Dict`
# iteration order is otherwise arbitrary, which would make output impossible to diff.
print_js(io::IO, x::AbstractDict) =
    print_object(io, (k => x[k] for k in sort!(collect(keys(x)); by = string)))
print_js(io::IO, x::NamedTuple) = print_object(io, pairs(x))

# Anything else is plain data as far as we are concerned.
print_js(io::IO, x) = JSON.json(io, x; allownan = true)

#-----------------------------------------------------------------------------# Buffers
# Typed arrays adopt the platform's byte order, and every platform Julia and browsers
# share is little-endian. Refuse to emit silently wrong numbers anywhere else.
function print_base64(io::IO, buffer::Vector{<:Number})
    ENDIAN_BOM == 0x04030201 || error("DeckGL emits little-endian buffers; this machine is big-endian")
    pipe = Base64EncodePipe(io)
    write(pipe, buffer)
    close(pipe)
    return nothing
end

# The JavaScript that rebuilds a packed buffer as a typed array in the page. Encoded
# straight into the output stream: at a million rows the base64 is the page.
typed_array_fn(::Vector{Float32}) = "DG.f32"
typed_array_fn(::Vector{UInt8}) = "DG.u8"

function print_typed_array(io::IO, buffer::Vector{<:Number})
    print(io, typed_array_fn(buffer), "(\"")
    print_base64(io, buffer)
    print(io, "\")")
end
