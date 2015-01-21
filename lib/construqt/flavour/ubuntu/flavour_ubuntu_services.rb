
module Construqt
  module Flavour
    module Ubuntu
      module Services
        class DhcpV4Relay
          def initialize(service)
            @service = service
          end

          def up(ifname, inbounds, upstreams)
            minus_i = (inbounds.map { |cqip| "-i #{cqip.container.interface.name}" }).join(' ')
            servers = upstreams.map{ |cqip| "-s #{cqip.to_s}" }.join(' ')
            #"/usr/sbin/dhcrelay -pf /run/dhcrelay-v4.#{ifname}.pid -q -4 #{minus_i} #{servers}"
            "/usr/sbin/dhcp-helper #{servers} #{minus_i} -r /run/dhcp-helper-v4.#{ifname}.pid"
          end

          def down(ifname, inbounds, upstreams)
            #"kill `cat /run/dhcrelay-v4.#{ifname}.pid`"
            "kill `cat /run/dhcp-helper-v4.#{ifname}.pid`"
          end

          def vrrp(host, ifname, vrrp)
            inbounds = Construqt::Tags.find(@service.inbound_tag).select{ |cqip| cqip.container.interface.host == host && cqip.ipv4? && !cqip.container.interface.name.empty? }
            return if inbounds.empty?
            iface = vrrp.interfaces.find{|_| _.host == host }
            return unless iface
            upstreams = Construqt::Tags.find(@service.upstream_tag).select{ |cqip| cqip.ipv4? }
            return if upstreams.empty?
            host.result.etc_network_vrrp(vrrp.name).add_master(up(ifname, inbounds, upstreams))
                                                    .add_backup(down(ifname, inbounds, upstreams))
            host.result.add_component(Construqt::Resources::Component::DHCPRELAY)
          end

          def interfaces(host, ifname, iface, writer)
            inbounds = Construqt::Tags.find(@service.inbound_tag).select{ |cqip| cqip.container.interface.host == host && cqip.ipv4? }
            return if inbounds.empty?
            upstreams = Construqt::Tags.find(@service.upstream_tag).select{ |cqip| cqip.ipv4? }
            return if upstreams.empty?
            writer.lines.up(up(ifname, inbounds, upstreams))
            writer.lines.down(down(ifname, inbounds, upstreams))
            host.result.add_component(Construqt::Resources::Component::DHCPRELAY)
          end
        end

        class DhcpV6Relay
          def initialize(service)
            @service = service
          end

          def up(ifname, inbounds, upstreams)
            inbound_ifs = inbounds.map { |cqip| "#{cqip.container.interface.name}" }.join(' ')
            minus_s = upstreams.map{ |cqip| "-s #{cqip}" }.join(' ')
            minus_r = upstreams.map{ |cqip| "-r #{ifname}" }.join(' ')
            #"/usr/sbin/dhcrelay -pf /run/dhcrelay-v6.#{ifname}.pid -q -6 #{minus_l} #{minus_o}"
            "/usr/sbin/dhcp6relay -d -p /run/dhcp6relay-v6.#{ifname}.pid #{minus_s} #{minus_r} #{inbound_ifs}"
          end

          def down(ifname, inbounds, upstreams)
            #"kill `cat /run/dhcrelay-v6.#{ifname}.pid`"
            "kill `cat /run/dhcp6relay-v6.#{ifname}.pid`"
          end

          def vrrp(host, ifname, vrrp)
            inbounds = Construqt::Tags.find(@service.inbound_tag).select{ |cqip| cqip.container.interface.host == host && cqip.ipv6? }
            return if inbounds.empty?
            iface = vrrp.interfaces.find{|_| _.host == host }
            return unless iface
            #binding.pry
            upstreams = Construqt::Tags.find(@service.upstream_tag).select{ |cqip| cqip.ipv6? }
            return if upstreams.empty?
            host.result.etc_network_vrrp(vrrp.name).add_master(up(ifname, inbounds, upstreams))
                                                    .add_backup(down(ifname, inbounds, upstreams))
            host.result.add_component(Construqt::Resources::Component::DHCPRELAY)
          end

          def interfaces(host, ifname, iface, writer)
            inbounds = Construqt::Tags.find(@service.inbound_tag).select{ |cqip| cqip.container.interface.host == host && cqip.ipv6? }
            return if inbounds.empty?
            upstreams = Construqt::Tags.find(@service.upstream_tag).select{ |cqip| cqip.ipv6? }
            return if upstreams.empty?
            writer.lines.up(up(ifname, inbounds, upstreams))
            writer.lines.down(down(ifname, inbounds, upstreams))
            host.result.add_component(Construqt::Resources::Component::DHCPRELAY)
          end
        end

        class Radvd
          def initialize(service)
            @service = service
          end

          def up(ifname)
            ret = "\n" + <<-OUT
            #https://github.com/reubenhwk/radvd/issues/33
            /usr/sbin/sysctl -w net.ipv6.conf.#{ifname}.autoconf=0
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
            host.result.etc_network_vrrp(iface.name).add_master(up(ifname)).add_backup(down(ifname))
          end

          def interfaces(host, ifname, iface, writer)
          end
        end

        class Null
          def initialize(service)
          end
          def up(ifname)
          end

          def down(ifname)
          end

          def vrrp(host, ifname, iface)
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
            Construqt::Services::IpsecStartStop => Null,
            Construqt::Services::BgpStartStop => Null,
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
