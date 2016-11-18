module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class IpProxyNeigh
            attr_reader :taste_type
            def initialize
              @taste_type = Entities::IpProxyNeigh
            end
            def render(iface, taste_type, taste)
              writer = etc_network_interfaces.get(iface, ud.ifname)
              ipv = ud.ip.ipv6? ? "-6 ": "-4 "
              writer.lines.up("ip #{ipv}neigh add proxy #{ud.ip.to_s} dev #{ud.ifname}", :extra)
              writer.lines.down("ip #{ipv}neigh del proxy #{ud.ip.to_s} dev #{ud.ifname}", :extra)
            end
          end
          add(IpProxyNeigh)
        end
      end
    end
  end
end
