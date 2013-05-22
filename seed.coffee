# A GameObject is a seed from which a thing can grow. Depending on what
# components you fertilise it with, it could grow into a player, or some lava,
# or a particle emitter.
#
# GameObjects can receive messages through .send('message', args...), and they
# have a reference to the world to which they belong. They have properties and
# state, like maybe a list of the types of burritos that this GameObject likes,
# or a clip from its favourite José González song. The properties are just
# JavaScript properties, but if you set them with .set({foo:bar}), components
# will be notified of the change. Object.observe() would be a neat way to do
# that, when it's eventually available.
#
# Components are functions, executed in the context of the GameObject. They can
# register to listen for messages and set up initial state. As a convenience,
# if you return a map of message name --> function from the component function,
# they will automatically be registered as message listeners.
#
# A component might look like this:
#
# GrowFlowers = ->
#   @flowerType = ['gardenia', 'buttercup', 'goldenrod'][Math.random()*3|0]
#   @timeToFlower = 3
#   grow: (type) ->
#     f = @world.make Flower
#     f.type = type
#     f.pos = x: @x, y: @y
#   update: (dt) ->
#     @timeToFlower -= dt
#     if @timeToFlower < 0
#       @timeToFlower = 3
#       @grow @flowerType
#
# You can build things in your game by combining components together. If you
# try to make your components small and well-defined, they will be reusable in
# other game things.
#
# For example, a flower queen character who grows flowers wherever she walks
# could be described so:
#
# FlowerQueen = [
#   [Positioned]
#   [RandomWander]
#   [GrowFlowers]
#   [AnimatedSprite, name: 'flowerqueen.png', tileSize: 16]
# ]
class GameObject
  constructor: (@world) ->
    @_messages = {}

  remove: ->
    @removeMe = yes
    @send 'removed'

  on: (e, f) ->
    (@[e] = (args...) -> @send e, args...) unless @[e]?
    (@_messages[e] ?= []).push f
    this

  send: (e, args...) -> f.apply(this, args) for f in (@_messages[e] ? []); return

  set: (props) ->
    for k, v of props
      old = @[k]
      @[k] = v
      @send "changed #{k}", old, v
    return

class World
  constructor: ->
    @entities = []

  make: (template) ->
    e = new GameObject this
    for c in template
      handlers = c[0].apply e, c[1..]
      if handlers
        e.on m, f for m, f of handlers
    @entities.push e
    e

  update: (dt) ->
    e.update? dt for e in @entities

    @entities = (e for e in @entities when not e.removeMe)
    return

  draw: ->
    e.draw?() for e in @entities
    return
