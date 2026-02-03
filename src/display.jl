#-----------------------------------------------------------------------------# MIME types
# Jupyter notebooks and VS Code use text/html
function Base.show(io::IO, ::MIME"text/html", deck::Deck)
    # Use iframe for isolation in notebook environments
    html = to_html(deck; height="500px")
    # Encode as base64 data URI to avoid escaping issues
    encoded = base64encode(html)
    print(io, """<iframe src="data:text/html;base64,$encoded" style="width:100%; height:520px; border:none;"></iframe>""")
end

# VS Code Julia extension specific MIME type
function Base.show(io::IO, ::MIME"juliavscode/html", deck::Deck)
    print(io, to_html(deck; height="500px"))
end

#-----------------------------------------------------------------------------# Display helpers
Base.showable(::MIME"text/html", ::Deck) = true
Base.showable(::MIME"juliavscode/html", ::Deck) = true
