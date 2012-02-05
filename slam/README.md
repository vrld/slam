SLAM
====
... is the **Simple [LOVE] Audio Manager** formerly known as the **Benignly
Designed Sound Manager.** It's a minimally invasive augmentation of [LOVE]'s
audio module. In contrast to sources that can only have one simultaneous
playing instance, SLAM sources create *instances* when played. This way you can
play one source multiple times at once. Each instance will inherit the settings
(volume, speed, looping, ...) of it's SLAM source, but can override them.

SLAM also features tags, which can be used to modify a number of sources at the
same time.

Example
-------

    require 'slam'
    function love.load()
        music = love.audio.newSource('music.ogg', 'stream') -- creates a new SLAM source
        music:setLooping(true)                              -- all instances will be looping
        music:setVolume(.3)                                 -- set volume for all instances
        love.audio.play(music)                              -- play music
        
        woosh = love.audio.newSource({'woosh1.ogg', 'woosh2.ogg'}, 'static')
    end
    
    function love.keypressed()
        local instance = woosh:play()                       -- creates a new instance
        instance:setPitch(.5 + math.random() * .5)          -- set pitch for this instance only
    end


Reference
---------

### Operations on Sources

    source = love.audio.newSource(what, how)

Returns a new SLAM source. Accepts the same parameters as
[love.audio.newSource](http://love2d.org/wiki/love.audio.newSource), with one
major difference: `what` can be a table, in which case each new playing
instance will pick an item of that table at random.


    instance = love.audio.play(source)
    instance = source:play()

Plays a source, removes all paused instances and returns a handle to the player
instance. Instances will inherit the settings (looping, pitch, volume) of
`source`.


    love.audio.stop(source)
    source:stop()

Stops all playing instances of a source.


    love.audio.stop()

Stops all playing instances.


    source:pause()

Pauses all playing instances of a source.


    source:resume()

Resumes all paused instances of a source. **Note:** source:play() clears paused
instances from a paused source.


    source:isStatic()

Returns `true` if the source is static, `false` otherwise.


    looping = source:isLooping()
    source:setLooping(looping)
    pitch = source:getPitch()
    source:setPitch(pitch)
    volume = source:getVolume()
    source:setVolume(volume)

Sets properties for all instances. Affects playing instances immediately. For
details on the parameters, see the [LOVE wiki](http://love2d.org/wiki/Source).


### Instances

All functions that affect LOVE Sources can be applied to SLAM instances. These
are:

    love.audio.pause(instance)
    instance:pause()
    instance:isPaused()
    
    love.audio.play(instance)
    instance:play()
    
    love.audio.resume(instance)
    instance:resume()
    
    love.audio.rewind(instance)
    instance:rewind()
    
    instance:getDirection()
    instance:setDirection()
    
    instance:getPitch()
    instance:setPitch()
    
    instance:getPosition()
    instance:setPosition()
    
    instance:getVelocity()
    instance:setVelocity()
    
    instance:getVolume()
    instance:setVolume()
    
    instance:isLooping()
    instance:setLooping()

See the [LOVE wiki](http://love2d.org/wiki/Source) for details.


### Tags

With tags you can group several sources together and call functions upon them.
A simple example:

    -- add some stuff to the background tag
    drums:addTags('music')
    baseline:addTags('background', 'music') -- a source can have multiple tags
    muttering:addTags('background')
    noise:addTags('background')
    cars:addTags('background')
    
    (...)
    
    love.audio.tags.background.setVolume(0) -- mute all background sounds
    love.audio.tags.music.setVolume(.1)     -- ... but keep the music alive


#### Functions

    source:addTags(tag, ...)

Adds one or more tags to a source. By default, all sources are member of the
tag `all`.


    source:removeTags(tag, ...)

Remove one or more tags from a source.


    love.audio.tags.TAG.FUNCTION(...)
    love.audio.tags[TAG].FUNCTION(...)

Calls `FUNCTION` on all sources tagged with `TAG`.


[LOVE]: http://love2d.org
