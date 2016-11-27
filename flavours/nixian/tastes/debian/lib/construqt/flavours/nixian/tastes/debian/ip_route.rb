module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class IpRoute
            def render(iface, taste_type, taste)
              route = ud.route
              writer = etc_network_interfaces.get(iface, ud.ifname)
              metric = ""
              metric = " metric #{route.metric}" if route.metric
              routing_table = ""
              routing_table = " table #{route.via.routing_table}" if route.via.routing_table
              writer.lines.up("ip route add #{route.dst.to_string} via #{route.via.to_s} dev #{ud.ifname} #{metric}#{routing_table}")
              writer.lines.down("ip route del #{route.dst.to_string} via #{route.via.to_s} dev #{ud.ifname} #{metric}#{routing_table}")
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpRoute, IpRoute)
        end
      end
    end
  end
end
