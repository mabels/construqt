module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class IpSecConnect
            def render(iface, taste_type, taste)
              writer = etc_network_interfaces.get(iface, iface.name)
              writer.lines.up("/usr/sbin/ipsec start", :extra) # no down this is also global
              writer.lines.up("/usr/sbin/ipsec up #{ud.name} &", 1000, :extra)
              writer.lines.down("/usr/sbin/ipsec down #{ud.name} &", -1000, :extra)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpSecConnect, IpSecConnect)
        end
      end
    end
  end
end
