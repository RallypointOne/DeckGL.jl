#-----------------------------------------------------------------------------# Row counts
# Layers routinely hold millions of rows. Count them only when the data can say how
# many it has without being materialized.
function row_count(data)
    Tables.istable(data) || return nothing
    rows = Tables.rows(data)
    Base.IteratorSize(typeof(rows)) === Base.SizeUnknown() ? nothing : length(rows)
end

#-----------------------------------------------------------------------------# REPL display
function Base.show(io::IO, layer::Layer)
    n = row_count(get(layer.props, :data, nothing))
    print(io, typename(layer), "(")
    n === nothing || print(io, n, n == 1 ? " row, " : " rows, ")
    print(io, length(layer.props), " props)")
end

# Widgets, views and view states are all a name and a bag of props.
function Base.show(io::IO, x::Union{Widget,View,ViewState})
    print(io, typename(x), "(",
          join(("$k=$(repr(v))" for (k, v) in sorted_props(x)), ", "), ")")
end

function Base.show(io::IO, ::MIME"text/plain", deck::Deck)
    println(io, "Deck with ", length(deck.layers), " layer", length(deck.layers) == 1 ? "" : "s", ":")
    for layer in deck.layers
        print(io, "  ")
        show(io, layer)
        println(io)
    end
    print(io, "  ")
    show(io, deck.initial_view_state)
    deck.map_style === nothing || print(io, "\n  basemap: ", deck.map_style)
end

function Base.show(io::IO, deck::Deck)
    n = length(deck.layers)
    print(io, "Deck(", n, " layer", n == 1 ? "" : "s", ")")
end

#-----------------------------------------------------------------------------# Rich display
# Escapes the two characters that would end an HTML attribute value, as the bytes go
# past, so a page can be written straight into a `srcdoc` without being built up as a
# string and copied.
struct AttributeEscape{T<:IO} <: IO
    io::T
end

function Base.unsafe_write(esc::AttributeEscape, p::Ptr{UInt8}, n::UInt)
    start = 1
    for i in 1:n
        byte = unsafe_load(p, i)
        (byte == UInt8('&') || byte == UInt8('"')) || continue
        i > start && unsafe_write(esc.io, p + start - 1, UInt(i - start))
        print(esc.io, byte == UInt8('&') ? "&amp;" : "&quot;")
        start = i + 1
    end
    n >= start && unsafe_write(esc.io, p + start - 1, n - start + 1)
    return n
end

Base.write(esc::AttributeEscape, byte::UInt8) = unsafe_write(esc, Ref(byte), UInt(1))

# Notebooks and doc pages get an iframe so the page's scripts and styles cannot reach the
# host document.
#
# `srcdoc` rather than a `data:` URI, which matters more than it looks: a `data:` URL is
# always an opaque origin, so the browser partitions its cache and every deck on a page
# downloads deck.gl -- 1.6 MB -- for itself. Thirty decks cost twenty megabytes of
# duplicate library. A same-origin `srcdoc` frame shares the cache and fetches it once.
# The cost is that `allow-same-origin` lets the frame reach the embedding page; the
# content is the user's own data rendered by deck.gl, and the frame still isolates
# styles and the DOM.
function Base.show(io::IO, ::MIME"text/html", deck::Deck)
    print(io, "<iframe loading=\"lazy\" style=\"width:100%;height:520px;border:none;\" ",
              "sandbox=\"allow-scripts allow-same-origin\" srcdoc=\"")
    to_html(AttributeEscape(io), deck; height = "500px")
    print(io, "\"></iframe>")
end

# The VS Code Julia extension renders this MIME type in its own webview, which is
# already isolated, so it gets the page directly.
Base.show(io::IO, ::MIME"juliavscode/html", deck::Deck) = to_html(io, deck)
