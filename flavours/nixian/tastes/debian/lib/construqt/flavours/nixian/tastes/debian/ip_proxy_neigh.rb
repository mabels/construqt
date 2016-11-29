module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class IpProxyNeigh
            #attr_reader :taste_type
            #def initialize
            #  @taste_type = Entities::IpProxyNeigh
            #end
            def onAdd(ud, taste, iface, me)
              binding.pry
              writer = taste.etc_network_interfaces.get(iface, me.ifname)
              writer.reference_up_down_sh(IpProxyNeigh)
              # ipv = me.ip.ipv6? ? "-6 ": "-4 "
              # writer.lines.up("ip #{ipv}neigh add proxy #{me.ip.to_s} dev #{me.ifname}", :extra)
              # writer.lines.down("ip #{ipv}neigh del proxy #{me.ip.to_s} dev #{me.ifname}", :extra)
            end

            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpProxyNeigh, IpProxyNeigh)
        end
      end
    end
  end
end
