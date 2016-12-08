


module Construqt
  module Flavour
    module Nixian
      module Services
        module ModulesConf
          class Service
            attr_reader :modules
            def initialize
              @path = File.join("etc", "modules-load.d", "construqt.conf")
              @modules = Set.new([
                "loop",
                "libcrc32c",
                "xt_multiport",
                "nf_conntrack_ipv4",
                "nf_defrag_ipv4",
                "nf_conntrack",
                "iptable_filter",
                "ip_tables",
                "x_tables",
                "af_key",
                "gre",
                "tun",
                "nf_conntrack_ipv6",
                "nf_defrag_ipv6",
                "ip6table_filter",
                "ip6_tables",
                "bonding",
                "8021q"
              ])
            end
            def get_path
              @path
            end
            def path(a)
              @path = a
              self
            end
            def module(a)
              @modules.add(a)
              self
            end
          end

          class Action
            def initialize(service)
              @service = service
            end
            def activate(context)
              @context = context
            end

            def commit
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              result.add(self, @service.modules.to_a.join("\n")+"\n",
                Construqt::Resources::Rights::root_0644,
                @service.get_path)
            end
          end

          class Factory
            attr_reader :machine
            def start(service_factory)
              @machine ||= service_factory.machine
                .service_type(Service)
                .depend(Construqt::Flavour::Nixian::Services::Result::Service)
            end

            def produce(host, srv_inst, ret)
              Action.new(srv_inst)
            end

          end
        end
      end
    end
  end
end
