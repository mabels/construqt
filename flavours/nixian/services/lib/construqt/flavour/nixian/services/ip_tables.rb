require_relative './ipsec/ipsec_cert_store'
require_relative './ipsec/ipsec_secret'
require_relative './result'
require_relative './etc_network_iptables'
require_relative './firewall'
module Construqt
  module Flavour
    module Nixian
      module Services
        module IpTables
          class Service
          end

          class OncePerHost

            attr_reader :host
            def initialize
              @etc_network_iptables = EtcNetworkIptables.new
            end

            def attach_host(host)
              @host = host
            end

            def activate(context)
              @context = context
            end

            def create(host, ifname, iface, family)
              throw 'interface must set' unless ifname
              Firewall.create_from_iface(ifname, iface, @etc_network_iptables)
              Firewall.create_from_iface(ifname, iface.delegate.vrrp.delegate, writer) if iface.delegate.vrrp
            end

            def build_config_host
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              result.add(EtcNetworkIptables, @etc_network_iptables.commitv4,
                         Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW4),
                         'etc', 'network', 'iptables.cfg')
              result.add(EtcNetworkIptables, @etc_network_iptables.commitv6,
                         Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW6),
                         'etc', 'network', 'ip6tables.cfg')

            end

            def post_interfaces
              # binding.pry
              up_downer = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
              up_downer.add(@host, Tastes::Entities::IpTables.new())
            end
          end

          class Action
          end

          class Factory
            attr_reader :machine
            def start(service_factory)
              @machine ||= service_factory.machine
                .service_type(Service)
                .result_type(OncePerHost)
                .depend(Result::Service)
                .depend(UpDowner::Service)
            end

            def produce(host, srv_inst, ret)
              Action.new()
            end
          end
        end
      end
    end
  end
end
