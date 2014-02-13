local lib = require("core.lib")
local app = require("core.app")
local buffer = require("core.buffer")
local basic = require("apps.basic.basic_apps")

local forwarder = {}

function forwarder:new()
   return setmetatable({}, {__index=forwarder})
end

local foo = { 'one', 'two', 'three' }
function forwarder:push()
   local l_in = self.input.input
   local l_out = self.output.output
   while not app.full(l_out) and not app.empty(l_in) do

      -- Uncommenting the traversal of the foo table in different
      -- sections causes vastly different behaviour of the app (either
      -- fast, 300MB memory footprint or slow, 900MB footprint)

      -- for k, v in ipairs(foo) do end
      local p = app.receive(l_in)
      -- for k, v in ipairs(foo) do end
      app.transmit(l_out, p)
   end
end

function forwarder:selftest()
   app.apps.source = app.new(basic.Source:new())
   app.apps.forward = app.new(forwarder:new())
   app.apps.sink = app.new(basic.Sink:new())

   app.connect("source", "output", "forward", "input")
   app.connect("forward", "output", "sink", "input")
   app.relink()
   buffer.preallocate(5000)
   local deadline = lib.timer(1e10)
   require("jit.p").start('vl4')
   repeat app.breathe() until deadline()
   require("jit.p").stop()
   app.report()
end

return forwarder
