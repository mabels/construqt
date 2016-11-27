module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class Tunnel
            def render(iface, taste_type, taste)
              writer = etc_network_interfaces.get(iface, iface.name)
              writer.lines.up("ip -#{ud.cfg.prefix} tunnel add #{iface.name} mode #{ud.cfg.mode} local #{ud.local} remote #{ud.remote}")
              writer.lines.down("ip -#{ud.cfg.prefix} tunnel del #{iface.name}")
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Tunnel, Tunnel)
        end
      end
    end
  end
end
