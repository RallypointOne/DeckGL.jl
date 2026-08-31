module DeckGLColorsExt

using Colors: Colorant, RGBA
import DeckGL

# deck.gl takes colors as bytes; Colors.jl works in normalized floats.
function DeckGL.to_color(c::Colorant)
    rgba = convert(RGBA{Float64}, c)
    return [round(Int, 255 * rgba.r), round(Int, 255 * rgba.g),
            round(Int, 255 * rgba.b), round(Int, 255 * rgba.alpha)]
end

end
