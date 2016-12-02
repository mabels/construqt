module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class IpRoute
            def on_add(ud, taste, iface, me)
              # binding.pry if iface.name == "etcbind-2"
              route = me.route
              metric = ""
              metric = " metric #{route.metric}" if route.metric
              routing_table = ""
              routing_table = " table #{route.via.routing_table}" if route.via.routing_table
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
              prefix = route.dst.ipv6? ? "-6" : "-4"
              fsrv.up("ip #{prefix} route add #{route.dst.to_string} via #{route.via.to_s} dev #{me.ifname} #{metric}#{routing_table}")
              fsrv.down("ip #{prefix} route del #{route.dst.to_string} via #{route.via.to_s} dev #{me.ifname} #{metric}#{routing_table}")
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
