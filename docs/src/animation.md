```@meta
DocTestSetup = quote
    using Luxor, Colors
    end
```
# Animation helper functions

Luxor provides some functions to help you create animations—at least, it provides some assistance in creating lots of individual frames that can later be stitched together to form a moving animation, such as a GIF or MP4.

There are four steps to creating an animation.

1 Use `Movie` to create a Movie object which determines the title and dimensions.

2 Define some functions that draw the graphics for specific frames.

3 Define one or more Scenes that call these functions for specific frames.

4 Call the `animate(movie::Movie, scenes)` function, passing in the scenes. This creates all the frames and saves them in a temporary directory. Optionally, you can ask for `ffmpeg` (if it's installed) to make an animated GIF for you.

## Example

```julia
demo = Movie(400, 400, "test")

function backdrop(scene, framenumber)
    background("black")
end

function frame(scene, framenumber)
    sethue(Colors.HSV(framenumber, 1, 1))
    eased_n = scene.easingfunction(framenumber, 0, 1, scene.framerange.stop)
    circle(polar(100, -π/2 - (eased_n * 2π)), 80, :fill)
    text(string("frame $framenumber of $(scene.framerange.stop)"),
        Point(O.x, O.y-190),
        halign=:center)
    text(scene.opts,
        boxbottomcenter(BoundingBox()),
        halign=:center,
        valign=:bottom)
end

animate(demo, [
    Scene(demo, backdrop, 0:359),
    Scene(demo, frame, 0:359,
        easingfunction=easeinoutcubic,
        optarg="made with Julia")
    ],
    creategif=true)
```

![animation example](assets/figures/animation.gif)

In this example, the movie uses two scenes, each specifying a function to draw frames from 0 to 359. For each frame numbered 0 to 359, the graphics are drawn by both the `backdrop()` and `frame()` functions, in that order. A drawing is automatically created (in PNG format) and centered (`origin()`) so you can start drawing immediately. The `finish()` function is automatically called when all the drawing functions in the scenes have completed, and the process starts afresh for the next frame. The second scene, calling the `frame()` function, shows how you can pass optional information to the function.

```@docs
Movie
Scene
animate
```

## Making the animation

For best results, you'll have to learn how to use something like `ffmpeg`, with its hundreds of options, which include codec selection, framerate adjustment and color palette tweaking. The `creategif` option for the `animate` function makes an attempt at running `ffmpeg` and assumes that it's already installed. Inside `animate()`, the first pass creates a GIF color palette, the second builds the file:

```julia
run(`ffmpeg -f image2 -i $(tempdirectory)/%10d.png -vf palettegen
    -y $(seq.stitle)-palette.png`)

run(`ffmpeg -framerate 30 -f image2 -i $(tempdirectory)/%10d.png
    -i $(seq.stitle)-palette.png -lavfi paletteuse -y /tmp/$(seq.stitle).gif`)
```

Many movie editing programs, such as Final Cut Pro, will also let you import sequences of still images into a movie timeline.

## Using scenes

Sometimes you want to construct an animation that has different components, layers, or scenes. To do this, you can specify scenes that are drawn only for specific frames.

As an example, consider a simple example showing the sun for each hour of a 24 hour day.

```
sun24demo = Movie(400, 400, "sun24", 0:23)
```

The `backgroundfunction()` draws a background that's used for all frames (animated GIFs like constant backgrounds):

```
function backgroundfunction(scene::Scene, framenumber)
    background("black")
end
```

A `nightskyfunction()` draws the night sky:

```
function nightskyfunction(scene::Scene, framenumber)
    sethue("midnightblue")
    box(O, 400, 400, :fill)
end
```

A `dayskyfunction()` draws the daytime sky:

```
function dayskyfunction(scene::Scene, framenumber)
    sethue("skyblue")
    box(O, 400, 400, :fill)
end
```

The `sunfunction()` draws a sun at 24 positions during the day:

```
function sunfunction(scene::Scene, framenumber)
    i = rescale(framenumber, 0, 23, 2pi, 0)
    gsave()
    sethue("yellow")
    circle(polar(150, i), 20, :fill)
    grestore()
end
```

Finally a `groundfunction()` draws the ground:

```
function groundfunction(scene::Scene, framenumber)
    gsave()
    sethue("brown")
    box(Point(O.x, O.y + 100), 400, 200, :fill)
    grestore()
    sethue("white")
end
```

Now define a group of Scenes that make up the movie. The scenes specify which functions are to be used, and for which frames:

```
backdrop  = Scene(sun24demo, backgroundfunction, 0:23)   # every frame
nightsky  = Scene(sun24demo, nightskyfunction, 0:6)      # midnight to 06:00
nightsky1 = Scene(sun24demo, nightskyfunction, 17:23)    # 17:00 to 23:00
daysky    = Scene(sun24demo, dayskyfunction, 5:19)       # 05:00 to 19:00
sun       = Scene(sun24demo, sunfunction, 6:18)          # 06:00 to 18:00
ground    = Scene(sun24demo, groundfunction, 0:23)       # every frame
```

Finally, the `animate` function scans the scenes in the scenelist for a movie, and calls the functions for each frame to build the animation:

```
animate(sun24demo, [
   backdrop, nightsky, nightsky1, daysky, sun, ground
   ],
   framerate=5,
   creategif=true)
```

![sun24 animation](assets/figures/sun24.gif)

Notice that for some frames, such as frame 0, 1, or 23, three of the functions are called: for others, such as 7 and 8, four or more functions are called. Also notice that the order of scenes and the use of backgrounds is important.

An alternative approach is to use the incoming framenumber as the master parameter that determines the position and appearance of all the graphics.

```
function frame(scene, framenumber)
    background("black")
    n   = rescale(framenumber, scene.framerange.start, scene.framerange.stop, 0, 1)
    n2π = rescale(n, 0, 1, 0, 2π)
    sethue(n, 0.5, 0.5)
    box(BoundingBox(), :fill)
    if 0.25 < n < 0.75
        sethue("yellow")
        circle(polar(150, n2π + π/2), 20, :fill)
    end
    if n < 0.25 || n > 0.75
        sethue("white")
        circle(polar(150, n2π + π/2), 20, :fill)
    end
end
```

### Passing information to the frame() function

If you want to pass information to the frame function, such as an array of values, try these:

```
function frame(scene, framenumber, datapoints)
...
end

somedata = Datapoints[...]

animate(demo, [
    Scene(demo, (s, f) -> frame(s, f, somedata),
        0:100,
        optarg=somedata)
    ],
    creategif=true,
    pathname="...")
```

## Easing functions

Transitions for animations often use non-constant and non-linear motions, and these are usually provided by *easing* functions. Luxor defines some of the basic easing functions and they're listed in the (unexported) array `Luxor.easingfunctions`. Each scene can have one easing function.

Most easing functions have names constructed like this:

```
ease[in|out|inout][expo|circ|quad|cubic|quart|quint]
```

and there's an `easingflat()` linear transition.

```@example
using Luxor # hide
function draweasingfunction(f, pos, w, h)
    @layer begin
        translate(pos)
        setline(0.5)
        sethue("black")
        box(O, w, h, :stroke)
        sethue("purple")
        for i in 0:0.005:1.0
            circle(Point(-w/2, h/2) + Point(w * i, -f(i, 0, h, 1)), 1, :fill)
        end
        sethue("black")
        text(replace(string(f), "Luxor." => ""), Point(0, h/2 - 20), halign=:center)
    end
end

Drawing(650, 650, "assets/figures/easingfunctions.png") # hide
background("white") # hide
origin() # hide
t = Tiler(650, 650, 5, 5)
margin=5
fontsize(10)
fontface("Menlo")
for (pos, n) in t
    n > length(Luxor.easingfunctions) && continue
    draweasingfunction(Luxor.easingfunctions[n], pos,
        t.tilewidth-margin, t.tileheight-margin)
end

finish() # hide
nothing # hide
```

In these graphs, the horizontal axis is time (between 0 and 1), and the vertical axis is the parameter value (between 0 and 1).

![easing function summary](assets/figures/easingfunctions.png)

One way to use an easing function in a frame-making function is like this:

```julia
function moveobject(scene, framenumber)
    background("white")
    ...
    easedframenumber = scene.easingfunction(framenumber, 0, 1, scene.framerange.stop)
    ...
```

This takes the current frame number, compares it with the end frame number of the scene, then adjusts it.

In the next example, the purple dot has sinusoidal easing motion, the green has cubic, and the red has quintic. They all traverse the drawing in the same time, but have different accelerations and decelerations.

![animation easing example](assets/figures/animation-easing.gif)

```julia
fastandfurious = Movie(400, 100, "easingtests")
backdrop(scene, framenumber) =  background("black")
function frame1(scene, framenumber)
    sethue("purple")
    eased_n = scene.easingfunction(framenumber, 0, 1, scene.framerange.stop)
    circle(Point(-180 + (360 * eased_n), -20), 10, :fill)
end
function frame2(scene, framenumber)
    sethue("green")
    eased_n = scene.easingfunction(framenumber, 0, 1, scene.framerange.stop)
    circle(Point(-180 + (360 * eased_n), 0), 10, :fill)
end
function frame3(scene, framenumber)
    sethue("red")
    eased_n = scene.easingfunction(framenumber, 0, 1, scene.framerange.stop)
    circle(Point(-180 + (360 * eased_n), 20), 10, :fill)
end
animate(fastandfurious, [
    Scene(fastandfurious, backdrop, 0:200),
    Scene(fastandfurious, frame1,   0:200, easingfunction=easeinsine),
    Scene(fastandfurious, frame2,   0:200, easingfunction=easeinoutcubic),
    Scene(fastandfurious, frame3,   0:200, easingfunction=easeinoutquint)
    ],
    creategif=true)
```

Here's the definition of one of the easing functions:

```
function easeoutquad(t, b, c, d)
    t /= d
    return -c * t * (t - 2) + b
end
```

Here:

- `t` is the current time (framenumber) of the transition

- `b` is the beginning value of the property

- `c` is the change between the beginning and destination value of the property

- `d` is the total length of the transition

```@docs
easingflat
lineartween
easeinquad
easeoutquad
easeinoutquad
easeincubic
easeoutcubic
easeinoutcubic
easeinquart
easeoutquart
easeinoutquart
easeinquint
easeoutquint
easeinoutquint
easeinsine
easeoutsine
easeinoutsine
easeinexpo
easeoutexpo
easeinoutexpo
easeincirc
easeoutcirc
easeinoutcirc
easeinoutinversequad
```
