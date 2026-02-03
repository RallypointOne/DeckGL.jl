const TEMPLATE_PATH = joinpath(@__DIR__, "assets", "template.html")

"""
    to_html(deck::Deck; width="100%", height="500px") -> String

Generate a standalone HTML string for the deck.gl visualization.
"""
function to_html(deck::Deck; width::String="100%", height::String="500px")
    template = read(TEMPLATE_PATH, String)
    spec_json = to_json(deck)

    html = replace(template,
        "{{SPEC_JSON}}" => spec_json,
        "{{WIDTH}}" => width,
        "{{HEIGHT}}" => height
    )

    return html
end

"""
    save_html(deck::Deck, path::String; width="100%", height="500px")

Save the visualization as a standalone HTML file.
"""
function save_html(deck::Deck, path::String; width::String="100%", height::String="500px")
    html = to_html(deck; width=width, height=height)
    write(path, html)
    return path
end

"""
    open_html(deck::Deck; width="100%", height="500px")

Open the visualization in the default web browser.
"""
function open_html(deck::Deck; width::String="100%", height::String="500px")
    path = tempname() * ".html"
    save_html(deck, path; width=width, height=height)

    # Open in default browser
    if Sys.isapple()
        run(`open $path`)
    elseif Sys.islinux()
        run(`xdg-open $path`)
    elseif Sys.iswindows()
        run(`cmd /c start $path`)
    end

    return path
end
