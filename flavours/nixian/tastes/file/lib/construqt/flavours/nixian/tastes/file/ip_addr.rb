module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class IpAddr
            def on_add(ud, taste, iface, me)
              # binding.pry if iface.name == "etcbind-2"
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
              prefix = me.ip.ipv6? ? "-6" : "-4"
              fsrv.up("ip #{prefix} addr add #{me.ip.to_string} dev #{me.ifname}")
              fsrv.down("ip #{prefix} addr del #{me.ip.to_string} dev #{me.ifname}")
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpAddr, IpAddr)
        end
      end
    end
  end
end
