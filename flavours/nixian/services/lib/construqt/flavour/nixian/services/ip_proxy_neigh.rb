require_relative './result'
# require_relative './etc_network_neigh'
module Construqt
  module Flavour
    module Nixian
      module Services
        module IpProxyNeigh
          class Service
          end

          class OncePerHost
          end

          class Action

            def initialize(host)
              @host = host
              #@etc_network_neigh = EtcNetworkNeigh.new
            end

            def proxy_neigh2ips(neigh)
              if neigh.nil?
                return []
              elsif neigh.respond_to?(:resolv)
                ret = neigh.resolv()
                #puts "self.proxy_neigh2ips>>>>>#{neigh} #{ret.map{|i| i.class.name}} "
                return ret
              end

              return neigh.ips
            end

            def activate(context)
              @context = context
            end

            def build_config_interface(iface)
              ups = []
              downs = []
              proxy_neigh2ips(iface.proxy_neigh).each do |ip|
                #puts "**********#{ip.class.name}"
                list = []
                if ip.network.to_string == ip.to_string
                  ip.each_host{|i| list << i }
                else
                  list << ip
                end

                list.each do |lip|
                  ipv = lip.ipv6? ? "-6 ": "-4 "
                  ups.push "ip #{ipv}neigh add proxy #{lip.to_s} dev #{iface.name}"
                  downs.push "ip #{ipv}neigh del proxy #{lip.to_s} dev #{iface.name}"
                end
              end

              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              if ups.length > 0
                blocks = ups
                result.add(IpProxyNeigh, Construqt::Util.render(binding, "interfaces_sh_envelop.erb"),
                           Construqt::Resources::Rights.root_0755,
                           'etc', 'network', "#{iface.name}-IpProxyNeigh-up.sh")
                blocks = downs.reverse
                result.add(IpProxyNeigh, Construqt::Util.render(binding, "interfaces_sh_envelop.erb"),
                           Construqt::Resources::Rights.root_0755,
                           'etc', 'network', "#{iface.name}-IpProxyNeigh-down.sh")
                # binding.pry if @host.name == "etcbind-1" and iface.name == "eth1"
                up_downer = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
                up_downer.add(@host, Tastes::Entities::IpProxyNeigh.new(iface))
              end
            end
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
              Action.new(host)
            end
          end
        end
      end
    end
  end
end
