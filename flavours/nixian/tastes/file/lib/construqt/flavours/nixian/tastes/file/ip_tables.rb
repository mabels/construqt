module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class IpTables
            def on_add(ud, taste, iface, me)
              # binding.pry if iface.name == "etcbind-2"
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
              fsrv.up("/sbin/iptables-restore /etc/network/iptables.cfg")
              fsrv.up("/sbin/ip6tables-restore /etc/network/ip6tables.cfg")
              fsrv.down("# no iptables-restore needed")
              fsrv.down("# no iptables-restore needed")
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpTables, IpTables)
        end
      end
    end
  end
end
