module Construqt
  module Flavour
    module Nixian
      module Services
        module DnsMasq
          class Service

          end

          class Action

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

            def activate(context)
              @context = context
            end

            def build_config_interface(iface)
              iface.address.ips && iface.address.ips.each do |ip|
                if ip.options && ip.options['dhcp']
                  result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
                  result.add_component(Construqt::Resources::Component::DNSMASQ)
                  up_downer = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
                  up_downer.add(@host, Tastes::Entities::DnsMasq.new(iface, ip.options['dhcp']))
                end
              end
            end
          end

          class Factory
            attr_reader :machine
            def start(service_factory)
              @machine ||= service_factory.machine
                .service_type(Service)
                .depend(Result::Service)
                .depend(UpDowner::Service)
            end

            def produce(host, srv_inst, ret)
              Action.new
            end
          end
        end
      end
    end
  end
end
