module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class IpSecConnect
            def on_add(ud, taste, iface, me)
              # binding.pry if iface.name == "etcbind-2"
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
              fsrv.up("/usr/sbin/ipsec start") # no down this is also global
              fsrv.up("/usr/sbin/ipsec up #{ud.name} &")
              fsrv.down("/usr/sbin/ipsec down #{ud.name} &")
              fsrv.down("/usr/sbin/ipsec stop")
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
