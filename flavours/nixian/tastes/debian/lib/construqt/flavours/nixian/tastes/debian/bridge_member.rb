
module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class BridgeMember
            def render(iface, taste_type, taste)
              writer = etc_network_interfaces.get(iface, ud.ifname)
              writer.lines.up "brctl addif #{ud.bname} #{ud.ifname}"
              writer.lines.down "brctl delif #{ud.bname} #{ud.ifname}"
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::BridgeMember, BridgeMember)
        end
      end
    end
  end
end
