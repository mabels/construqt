module Construqt
  module Flavour
    module Nixian
      module Dialect
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
          end
        end
      end
    end
  end
end
