module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          module Services

            class DhcpV6Relay
              def initialize(service)
                @service = service
              end

              def register_taste(host)
                host.result.up_downer.tastes.each do |t|
                  if t.kind_of?(Result::UpDownerDebianTaste)
                    t.dispatch[Tastes::Entities::DhcpV6Relay.name] = lambda {|i, u| render_debian(t, i, u) }
                  elsif t.kind_of?(Result::UpDownerFlatTaste)
                    t.dispatch[Tastes::Entities::DhcpV6Relay.name] = lambda {|i, u| render_flat(t, i, u) }
                  elsif t.kind_of?(Result::UpDownerSystemdTaste)
                    t.dispatch[Tastes::Entities::DhcpV6Relay.name] = lambda {|i, u| render_systemd(t, i, u) }
                  else
                    throw "unknown tast"
                  end
                end
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

              def render_debian(t, iface, ud)
                writer = t.etc_network_interfaces.get(iface, ud.ifname)
                writer.lines.up(up(ud.ifname), :extra)
                writer.lines.down(down(ud.ifname), :extra)
              end

              def render_flat(t, i, ud)
                t.up(up(ud.ifname))
                t.down(down(ud.ifname))
              end

              def render_systemd(t, i, u)
              end

              def vrrp(host, ifname, vrrp)
                inbounds = Construqt::Tags.find(@service.inbound_tag).select{ |cqip| cqip.container.interface.host.eq(host) && cqip.ipv6? }
                return if inbounds.empty?
                iface = vrrp.interfaces.find{|_| _.host.eq(host) }
                return unless iface
                #binding.pry
                upstreams = Construqt::Tags.find(@service.upstream_tag).select{ |cqip| cqip.ipv6? }
                return if upstreams.empty?
                host.result.etc_network_vrrp(vrrp.name).add_master(up(ifname, inbounds, upstreams))
                  .add_backup(down(ifname, inbounds, upstreams))
                host.result.add_component(Construqt::Resources::Component::DHCPRELAY)
              end

              def build_interface(host, ifname, iface, writer)
                inbounds = Construqt::Tags.find(@service.inbound_tag).select{ |cqip| cqip.container.interface.host.eq(host) && cqip.ipv6? }
                return if inbounds.empty?
                upstreams = Construqt::Tags.find(@service.upstream_tag).select{ |cqip| cqip.ipv6? }
                return if upstreams.empty?
                host.result.up_downer.add(iface, Tastes::Entities::DhcpV6Relay.new(xxxx))
                writer.lines.up(up(ifname, inbounds, upstreams), :extra)
                writer.lines.down(down(ifname, inbounds, upstreams), :extra)
                host.result.add_component(Construqt::Resources::Component::DHCPRELAY)
              end
            end
            Services.add_renderer(Construqt::Services::DhcpV6Relay, DhcpV6Relay)

          end
        end
      end
    end
  end
end
