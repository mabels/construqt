module Construqt
  module Flavour
    module Nixian
      module Services
        class DhcpClient
          def initialize()
          end
        end

        class DhcpClientAction
        end

        class DhcpClientFactory
          attr_reader :machine
          def initialize(service_factory)
            @machine = service_factory.machine
              .service_type(DhcpClient)
              .depend(Result)
          end

          def produce(host, srv_inst, ret)
            DhcpClientAction.new
          end
        end

        class DhcpClientAction

          attr_reader :service_type
          def initialize
            @service_type = DhcpClient
          end

          def produce(host, srv_inst, ret)
            DhcpClientAction.new
          end

          def register_taste(host)
            host.result.up_downer.tastes.each do |t|
              if t.kind_of?(Result::UpDownerDebianTaste)
                t.dispatch[Tastes::Entities::DhcpClient.name] = lambda {|i, u| render_debian(t, i, u) }
              elsif t.kind_of?(Result::UpDownerFlatTaste)
                t.dispatch[Tastes::Entities::DhcpClient.name] = lambda {|i, u| render_flat(t, i, u) }
              elsif t.kind_of?(Result::UpDownerSystemdTaste)
                t.dispatch[Tastes::Entities::DhcpClient.name] = lambda {|i, u| render_systemd(t, i, u) }
              else
                throw "unknown tast"
              end
            end
          end

          def up(ifname, inbounds, upstreams)
          end

          def down(ifname, inbounds, upstreams)
          end

          def render_debian(t, iface, ud)
            return if iface.address.nil?
            return if !iface.address.dhcpv4?
            host.result.up_downer.add(iface, Tastes::Entities::DhcpClient.new(ifname))
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
            # register_taste(host.delegate)
          end
        end
      end
    end
  end
end
