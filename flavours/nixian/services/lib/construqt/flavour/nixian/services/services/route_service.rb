module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          module Services

            class RouteService
              def initialize(service)
                @service = service
              end

              def up(ifname)
                "/sbin/ip route add #{@service.rt.dst.to_string} via #{@service.rt.via}"
              end

              def down(ifname)
                "/sbin/ip route del #{@service.rt.dst.to_string} via #{@service.rt.via}"
              end

              def vrrp(host, ifname, iface)
                host.result.etc_network_vrrp(iface.name).add_master(up(ifname)).add_backup(down(ifname))
              end

              def interfaces(host, ifname, iface, writer)
              end
            end
          end
        end
      end
    end
  end
end
