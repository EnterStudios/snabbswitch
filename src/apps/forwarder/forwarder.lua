local app = require("core.app")
local link = require("core.link")
local ffi = require("ffi")

local forwarder = {}

function forwarder:new()
   return setmetatable({}, {__index=forwarder})
end

-- Avoid "boxing" by pre-allocating a boxed ctype object
-- and only manipulating the contents of it 
local p = ffi.new("struct packet*[1]")
function forwarder:push()
   local l_in = self.input.input
   local l_out = self.output.output
   while not link.full(l_out) and not link.empty(l_in) do
      p[0] = ffi.C.link_receive(l_in)
      ffi.C.link_transmit(l_out, p[0])
   end
end

function forwarder.selftest()
   local lib = require("core.lib")
   local app = require("core.app")
   local config = require("core.config")
   local buffer = require("core.buffer")
   local basic = require("apps.basic.basic_apps")

   local c = config.new()
   config.app(c, 'source', basic.Source)
   config.app(c, 'forward', forwarder)
   config.app(c, 'sink', basic.Sink)

   config.link(c, "source.output -> forward.input")
   config.link(c, "forward.output -> sink.input")
   app.configure(c)
   buffer.preallocate(5000)
   require("jit.opt").start("-sink")
   require("jit.p").start('vl5')
   app.main({duration = 5})
   require("jit.p").stop()
end

return forwarder
