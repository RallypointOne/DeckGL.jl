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
# Notebooks get an iframe so the page's scripts and styles cannot reach the host
# document. The page is encoded straight into the `src` attribute as it is generated,
# rather than built and then encoded.
function Base.show(io::IO, ::MIME"text/html", deck::Deck)
    print(io, """<iframe src="data:text/html;base64,""")
    pipe = Base64EncodePipe(io)
    to_html(pipe, deck; height = "500px")
    close(pipe)
    print(io, """" style="width:100%;height:520px;border:none;" sandbox="allow-scripts"></iframe>""")
end

# The VS Code Julia extension renders this MIME type in its own webview, which is
# already isolated, so it gets the page directly.
Base.show(io::IO, ::MIME"juliavscode/html", deck::Deck) = to_html(io, deck)
