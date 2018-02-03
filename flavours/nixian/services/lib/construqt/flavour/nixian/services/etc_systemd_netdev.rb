module Construqt
  module Flavour
    module Nixian
      module Services
        module EtcSystemdNetdev
          class SystemdNetdev
            attr_reader :interface
            def initialize(iface)
              @interface = iface
            end

            def drop_ins
              {}
            end

            def name
              @interface.name
            end

            def kind
              # binding.pry if @interface.name == "gt6rtwlmgt"
              if @interface.delegate.respond_to?(:kind)
                @interface.delegate.kind
              else
                @interface.delegate.clazz
              end
            end

            def tunnel_mode
              @interface.delegate.tunnel_mode if @interface.delegate.respond_to?(:tunnel_mode)
            end

            def vlan_id
              @interface.delegate.vlan_id if @interface.delegate.respond_to?(:vlan_id)
            end

            def is_enable
              true
            end

            def get_skip_content
              false
            end

            def as_string
              systemd_netdev = self
              iface = @interface
              # binding.pry
              Construqt::Util.render(binding, "systemd_netdev.erb")
            end

            def as_systemd_file
              as_string
            end

            def get_command
              nil
            end

            def get_name
              # idx = @interface.host.interfaces.values.find_index(@interface)
              "#{name}.netdev"
            end

            def commit(result)
              result.add(self, self.as_string,
                Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::SYSTEMD),
                "etc", "systemd", "network", self.get_name)
            end
          end

          class OncePerHost
            attr_reader :interfaces
            def initialize
              @interfaces = {}
            end

            def activate(context)
              @context = context
              pbuilder = @context.find_instances_from_type Construqt::Flavour::Nixian::Services::Packager::OncePerHost
              pbuilder.register(Construqt::Resources::Component::SYSTEMD)
            end

            def add(iface)
              @interfaces[iface.name] ||= SystemdNetdev.new(iface)
            end

            def netdevs
              @interfaces.values
            end

            def commit
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              @interfaces.values.each do |sysdev|
                # binding.pry if sysdev.interface.name == "docker0"
                next unless sysdev.interface.startup?
                sysdev.commit(result)
              end
            end
          end

          class Service
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
                .depend(Packages::Builder)
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
