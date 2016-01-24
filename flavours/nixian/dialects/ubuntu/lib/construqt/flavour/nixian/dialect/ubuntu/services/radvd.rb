module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          module Services

            class Radvd
              def initialize(service)
                @service = service
              end

              def up(ifname)
                ret = "\n" + <<-OUT
            #https://github.com/reubenhwk/radvd/issues/33
            /sbin/sysctl -w net.ipv6.conf.#{ifname}.autoconf=0
            /usr/sbin/radvd -C /etc/network/radvd.#{ifname}.conf -p /run/radvd.#{ifname}.pid
                OUT
              end

              def down(ifname)
                "kill `cat /run/radvd.#{ifname}.pid`"
              end

              def vrrp(host, ifname, iface)
                #binding.pry
                host.result.etc_network_vrrp(iface.name).add_master(up(ifname)).add_backup(down(ifname))
              end

              def interfaces(host, ifname, iface, writer, family = nil)
                #      binding.pry
                return unless iface.address && iface.address.first_ipv6
                writer.lines.up(up(ifname))
                writer.lines.down(down(ifname))
                host.result.add(self, <<RADV, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::RADVD), "etc", "network", "radvd.#{ifname}.conf")
interface #{ifname}
{
        AdvManagedFlag on;
        AdvSendAdvert on;
        AdvOtherConfigFlag on;
        #AdvAutonomous on;
        #AdvLinkMTU 1480;
        #MinRtrAdvInterval 3;
        #MaxRtrAdvInterval 60;
        prefix #{iface.address.first_ipv6.network.to_string}
        {
                AdvOnLink on;
                AdvAutonomous #{@service.adv_autonomous? ? "on" : "off"};
                AdvRouterAddr on;
        };

};
RADV
              end
            end
          end
        end
      end
    end
  end
end
