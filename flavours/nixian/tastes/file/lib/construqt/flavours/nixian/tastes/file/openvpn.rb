module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class OpenVpn
            def on_add(ud, taste, iface, me)
              # binding.pry if iface.name == "etcbind-2"
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
              fsrv.up("mkdir -p /dev/net")
              fsrv.up("mknod /dev/net/tun c 10 200")
              fsrv.up("/usr/sbin/openvpn --config /etc/openvpn/#{iface.name}.conf")
              fsrv.down("kill $(cat /run/openvpn.#{iface.name}.pid)")
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::OpenVpn, OpenVpn)
        end
      end
    end
  end
end
