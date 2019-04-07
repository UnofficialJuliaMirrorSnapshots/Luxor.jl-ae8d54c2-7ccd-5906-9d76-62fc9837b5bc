#!/usr/bin/env julia

using Luxor

using Test

using Random
Random.seed!(42)

function textbox_tests(fname)
    Drawing(1000, 1000, fname)
    origin()
    setopacity(0.8)
    sethue("black")
    fontface("Georgia-Bold")
    tiles = Tiler(1000, 1000, 4, 3, margin=50)
    for (pos, n) in tiles
        fsize = 10
        fontsize(fsize)
        @layer begin
            translate(pos)
            sethue("ivory")
            box(O, tiles.tilewidth-2, tiles.tileheight-2, :fill)
            sethue("black")
            # even-numbered boxes split and count
            if iseven(n)
                opacity = 1.0
                # split on ., (, and )
                textbox(split("Luxor is a city in Upper (southern) Egypt. " ^ 6, r"\.|\(|\)"),
                O - (tiles.tilewidth/2 - 2, tiles.tileheight/2 - 2),
                # l is linenumber, t is the text of a line, p is the position of the start of the line, h is the interline height
                linefunc = (l, t, p, h) ->
                    begin
                        # add length of line at end
                        @layer begin
                            fontsize(8)
                            fontface("Menlo")
                            text(string(length(t)), p + (tiles.tilewidth - 20, 0))
                        end
                    end,
                    leading=10)
            else
                # odd-numbered boxes number and fade
                # split on the letter "y"
               textbox(split("Luxor is a city in Upper (southern) Egypt. " ^ 6, "y"),
                O - (tiles.tilewidth/2 - 2, tiles.tileheight/2 - 2),
                linefunc = (l, t, p, h) ->
                    begin
                        text(string(l), p + (tiles.tilewidth - 20, 0))
                        setopacity(rescale(l, 1, 10, 1.0, 0.3))
                    end,
                    leading=12)
            end
        end
    end

    fontsize(80)
    textbox("LUXOR", alignment=:center)
    
    @test finish() == true
    println("...finished test: output in $(fname)")
end

textbox_tests("textbox-tests.png")
