
module Construct
  module Flavour
    module Ubuntu
      module Services
        class DhcpV4Relay
          def initialize(service)
            @service = service
          end

          def prefix(unused, unused2)
          end

          def up(ifname)
            "/usr/sbin/dhcrelay -pf /run/dhcrelay-v4.#{ifname}.pid -d -q -4 -i #{ifname} #{@service.servers.map{|i| i.to_s}.join(' ')}"
          end

          def down(ifname)
            "kill `/run/dhcrelay-v4.#{ifname}.pid`"
          end

          def vrrp(host, ifname, iface)
            host.result.etc_network_vrrp(iface.name).add_master(up(ifname)).add_backup(down(ifname))
          end

          def interfaces(host, ifname, iface, writer)
            #binding.pry
            return unless iface.address && iface.address.first_ipv4
            return if @service.servers.empty?
            writer.lines.up(up(ifname))
            writer.lines.down(down(ifname))
          end
        end

        class DhcpV6Relay
          def initialize(service)
            @service = service
          end

          def prefix(unused, unused2)
          end

          def up(ifname)
            "/usr/sbin/dhcrelay -pf /run/dhcrelay-v6.#{ifname}.pid -d -q -6 -i #{ifname} #{@service.servers.map{|i| i.to_s}.join(' ')}"
          end

          def down(ifname)
            "kill `/run/dhcrelay-v6.#{ifname}.pid`"
          end

          def vrrp(host, ifname, iface)
            host.result.etc_network_vrrp(iface.name).add_master(up(ifname)).add_backup(down(ifname))
          end

          def interfaces(host, ifname, iface, writer)
            return unless iface.address && iface.address.first_ipv6
            return if @service.servers.empty?
            writer.lines.up(up(ifname))
            writer.lines.down(down(ifname))
          end
        end

        class Radvd
          def initialize(service)
            @service = service
          end

          def prefix(unused, unused2)
          end

          def up(ifname)
            "/usr/sbin/radvd -C /etc/network/radvd.#{ifname}.conf -p /run/radvd.#{ifname}.pid"
          end

          def down(ifname)
            "kill `cat /run/radvd.#{ifname}.pid`"
          end

          def vrrp(host, ifname, iface)
            #binding.pry
            host.result.etc_network_vrrp(iface.name).add_master(up(ifname)).add_backup(down(ifname))
          end

          def interfaces(host, ifname, iface, writer)
            #      binding.pry
            return unless iface.address && iface.address.first_ipv6
            writer.lines.up(up(ifname))
            writer.lines.down(down(ifname))
            host.result.add(self, <<RADV, Construct::Resources::Rights::ROOT_0644, "etc", "network", "radvd.#{ifname}.conf")
interface #{ifname}
{
        AdvManagedFlag on;
        AdvSendAdvert on;
        #AdvAutonomous on;
        AdvLinkMTU 1480;
        AdvOtherConfigFlag on;
        MinRtrAdvInterval 3;
        MaxRtrAdvInterval 60;
        prefix #{iface.address.first_ipv6.network.to_string}
        {
                AdvOnLink on;
        #       AdvAutonomous on;
                AdvRouterAddr on;
        };

};
RADV
          end
        end

        def self.get_renderer(service)
          factory = {
            Construct::Services::DhcpV4Relay => DhcpV4Relay,
            Construct::Services::DhcpV6Relay => DhcpV6Relay,
            Construct::Services::Radvd => Radvd
          }
          found = factory.keys.find{ |i| service.kind_of?(i) }
          throw "service type unknown #{service.name} #{service.class.name}" unless found
          factory[found].new(service)
        end
      end
    end
  end
end
