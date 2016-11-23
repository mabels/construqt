module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class IpProxyNeigh
            #attr_reader :taste_type
            #def initialize
            #  @taste_type = Entities::IpProxyNeigh
            #end
            def onAdd(ud, taste, iface, me)
              result = ud.result_types.find_by_service_type(Construqt::Flavour::Nixian::Services::Result)
              ipv = me.ip.ipv6? ? "-6 ": "-4 "
              result.add(IpProxyNeigh, "ip #{ipv}neigh add proxy #{me.ip.to_s} dev #{me.ifname}",
                Construqt::Resources::Rights.root_0755,
                'etc', 'network', "#{iface.name}-#{me.class.name.split("::").last}-up.sh")
              result.add(IpProxyNeigh, "ip #{ipv}neigh del proxy #{me.ip.to_s} dev #{me.ifname}",
                Construqt::Resources::Rights.root_0755,
                'etc', 'network', "#{iface.name}-#{me.class.name.split("::").last}-down.sh")
            end

          end
          add(Entities::IpProxyNeigh, IpProxyNeigh)
        end
      end
    end
  end
end
