
module Construqt
  module Flavour
    module Ubuntu
      module Services
        class DhcpV4Relay
          def initialize(service)
            @service = service
          end

          def up(ifname)
            "/usr/sbin/dhcrelay -pf /run/dhcrelay-v4.#{ifname}.pid -q -4 #{@service.inbound.map{|i| "-i #{i.name}"}.join(' ')} #{@service.upstream.map{|i| i.to_s}.join(' ')}"
          end

          def down(ifname)
            "kill `cat /run/dhcrelay-v4.#{ifname}.pid`"
          end

          def vrrp(host, ifname, iface)
            host.result.etc_network_vrrp(iface.name).add_master(up(ifname)).add_backup(down(ifname))
          end

          def interfaces(host, ifname, iface, writer)
            inbounds = @service.inbounds.select{ |i| i.host == host }
            upstreams = @service.upstreams.select{ |i| i.host == host }
            unless inbounds.find{|_iface| _iface.address && !_iface.address.v4s.empty? }
              Construqt::Logger.warn("DhcpV6Relay no ipv4 address inbounds found")
              return
            end
            unless upstreams.find{|_iface| _iface.address && !_iface.address.v4s.empty? }
              Construqt::Logger.warn("DhcpV6Relay no ipv4 address upstreams found")
              return
            end
            binding.pry
            writer.lines.up(up(ifname))
            writer.lines.down(down(ifname))
          end
        end

        class DhcpV6Relay
          def initialize(service)
            @service = service
          end

          def up(ifname, inbounds, upstreams)
            binding.pry
            minus_l = inbounds.map { |cqip| "-l #{cqip}%#{cqip.container.interface.name}" }.join(' ')
            minus_o = upstreams.map{ |cqip| "-u #{cqip}%#{cqip.container.interface.name}" }.join(' ')
            "/usr/sbin/dhcrelay -pf /run/dhcrelay-v6.#{ifname}.pid -q -6 #{minus_l} #{minus_o}"
          end

          def down(ifname, inbounds, upstreams)
            "kill `cat /run/dhcrelay-v6.#{ifname}.pid`"
          end

          def vrrp(host, ifname, iface)
            inbounds = Construqt::Tags.find(@service.inbound_tag).select{ |cqip| cqip.container.interface.host == host && cqip.ipv6? }
            return if inbounds.empty?
            host.result.etc_network_vrrp(iface.name).add_master(up(ifname, inbounds, [iface.address.first_ipv6]))
                                                    .add_backup(down(ifname, inbounds, [iface.address.first_ipv6]))
          end

          def interfaces(host, ifname, iface, writer)
            inbounds = Construqt::Tags.find(@service.inbound_tag).select{ |cqip| cqip.container.interface.host == host && cqip.ipv6? }
            return if inbounds.empty?
            writer.lines.up(up(ifname, inbounds, [iface.address.first_ipv6]))
            writer.lines.down(down(ifname, inbounds, [iface.address.first_ipv6]))
          end
        end

        class Radvd
          def initialize(service)
            @service = service
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
            host.result.add(self, <<RADV, Construqt::Resources::Rights::ROOT_0644, "etc", "network", "radvd.#{ifname}.conf")
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
                AdvAutonomous off;
                AdvRouterAddr on;
        };

};
RADV
          end
        end

        class ConntrackD
          def initialize(service)
            @service = service
          end

          def up(ifname)
            "/usr/share/doc/conntrackd/examples/sync/primary-backup.sh primary"
          end

          def down(ifname)
            "/usr/share/doc/conntrackd/examples/sync/primary-backup.sh backup"
          end

          def vrrp(host, ifname, iface)
            #binding.pry
            host.result.etc_network_vrrp(iface.name).add_master(up(ifname)).add_backup(down(ifname))
          end

          def interfaces(host, ifname, iface, writer)
            throw "only vrrp ifaces could be used to conntrack: #{ifname}:#{iface.name}" unless iface.vrrp
            throw "conntrack needs a ipv4 address #{ifname}:#{iface.name}" unless iface.address.first_ipv4
            throw "conntrack currently a ipv4 address #{iface.host.name}:#{ifname}:#{iface.name}" unless iface.address.first_ipv4
            other_if = iface.vrrp.delegate.interfaces.find{|i| i.host != host }
            throw "conntrack currently a ipv4 address #{other_if.host.name}:#{other_if.name}" unless other_if.address.first_ipv4
            #binding.pry
            host.result.etc_conntrackd_conntrackd.add(ifname, iface.address.first_ipv4, other_if.address.first_ipv4)
          end
        end

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
            #binding.pry
            host.result.etc_network_vrrp(iface.name).add_master(up(ifname)).add_backup(down(ifname))
          end

          def interfaces(host, ifname, iface, writer)
          end
        end

        def self.get_renderer(service)
          factory = {
            Construqt::Services::DhcpV4Relay => DhcpV4Relay,
            Construqt::Services::DhcpV6Relay => DhcpV6Relay,
            Construqt::Services::Radvd => Radvd,
            Construqt::Services::ConntrackD => ConntrackD,
            Construqt::Flavour::Ubuntu::Vrrp::RouteService => RouteService
          }
          found = factory.keys.find{ |i| service.kind_of?(i) }
          throw "service type unknown #{service.name} #{service.class.name}" unless found
          factory[found].new(service)
        end
      end
    end
  end
end
