module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class IpRoute
            def on_add(ud, taste, iface, me)
              route = me.route
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface, me.ifname)
              unless route.is_global?
                metric = ""
                metric = " metric #{route.metric}" if route.metric
                routing_table = ""
                routing_table = " table #{route.via.routing_table}" if route.via.routing_table
                writer.lines.up("ip route add #{route.dst.to_string} via #{route.via.to_s} dev #{Util.short_ifname(iface)} #{metric}#{routing_table}")
                writer.lines.down("ip route del #{route.dst.to_string} via #{route.via.to_s} dev #{Util.short_ifname(iface)} #{metric}#{routing_table}")
              end
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
