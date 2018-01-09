module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class IpTables
            def on_add(ud, taste, iface, me)
              #binding.pry if iface.nil? or iface.name == "etcbind-2"
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface.interfaces.values.first)
              # binding.pry
              ipt = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::IpTables::OncePerHost)
              unless ipt.etc_network_iptables.commitv4.empty?
                writer.lines.up("/sbin/iptables-restore /etc/network/iptables.cfg")
              end
              unless ipt.etc_network_iptables.commitv6.empty?
                writer.lines.up("/sbin/ip6tables-restore /etc/network/ip6tables.cfg")
              end
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
