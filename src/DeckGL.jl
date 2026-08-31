module DeckGL

using Base64: base64encode, Base64EncodePipe
using Artifacts, LazyArtifacts
using JSON
using Tables

#------------------------------------------------------------------------------# exports
include("metadata.jl")  # generated from deck.gl itself

for name in [LAYER_NAMES; WIDGET_NAMES; VIEW_NAMES]
    @eval export $name
end

export
    Deck, Layer, View, ViewState, Widget, JS,    # Core types
    to_js, to_html, save_html, open_html         # Rendering


include("js.jl")
include("spec.jl")
include("data.jl")
include("render.jl")
include("display.jl")
include("convenience.jl")


end # module
