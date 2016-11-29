module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class IpTables
            def on_add(ud, taste, iface, me)
              # binding.pry if iface.name == "fanout-de"
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface)
              writer.lines.up("/sbin/iptables-restore /etc/network/iptables.cfg")
              writer.lines.up("/sbin/ip6tables-restore /etc/network/ip6tables.cfg")
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
