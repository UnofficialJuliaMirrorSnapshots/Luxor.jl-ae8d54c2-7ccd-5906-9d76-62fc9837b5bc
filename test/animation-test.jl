#!/usr/bin/env julia

using Luxor

using Test

using Colors

using Random

Random.seed!(42)

demomovie = Movie(400, 400, "test", 0:359)

function backdrop(scene, framenumber)
    background("black")
end

function frame(scene, framenumber)
    sethue(Colors.HSV(framenumber, 1, 1))
    p = scene.easingfunction(framenumber, 0, 1, scene.framerange.stop)
    circle(polar(100, -pi/2 - p * 2pi), 80, :fill)
    text(string("frame $framenumber of $(length(scene.movie.movieframerange))"), Point(O.x, O.y-190))
end

mktempdir() do tmpdir
    @test animate(demomovie, [Scene(demomovie, backdrop), Scene(demomovie, frame, 0:359, easingfunction=easeinoutquad)], creategif=false) == true
end

demo = Movie(400, 100, "test")

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

function frame4(scene, framenumber)
    sethue("red")
    eased_n = scene.easingfunction(framenumber, 0, 1, scene.framerange.stop)
    circle(Point(-180 + (360 * eased_n), 20), 10, :fill)
    sethue("white")
    fontsize(20)
    text(string(scene.opts))
end

mktempdir() do tmpdir
    @test animate(demo, [
        Scene(demo, backdrop, 0:200),
        Scene(demo, frame1,   0:200, easingfunction=easeinsine),
        Scene(demo, frame2,   0:200, easingfunction=easeinoutcubic),
        Scene(demo, frame3,   0:200, easingfunction=easeinoutquint),
        Scene(demo, frame4,   0:200, easingfunction=easeinoutquint, optarg=42),
        ],
        creategif=false) == true
end

@testset "test pathname parameter of animate()" begin
    mktempdir() do tmpdir
        # test that animation is saved to 'pathname' if valid pathname is given
        testfile = joinpath(tmpdir, "test.gif")
        
        #= ffmpeg is not supported on travis and co -> disable gif generation
        # dependent test
        @test !isfile(testfile)
        =#
        @test animate(demo, Scene(demo, backdrop, 0:200),
            creategif=false,
            pathname=testfile) == true
            
        touch(testfile)
        @test isfile(testfile)
         
        # test that error is thrown if the passed pathname points to a directory
        # and that the content of that directory is not removed (ticket #57)
        @test isdir(tmpdir)
        @test animate(demo, Scene(demo, backdrop, 0:200),
            creategif=false,
            pathname=tmpdir) == false
         @test isfile(testfile)
    end
end

println("...finished animation tests")
