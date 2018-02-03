module Construqt
  module Flavour
    module Nixian
      module Services
        module EtcSystemdNetwork
          class SystemdNetwork
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

            def tunnels
              inode = @interface.host.interface_graph.node_from_ref(@interface)
              ret = inode.children.select{|link| link.link.ref.clazz == "tunnel"}.map{|i| i.link.ref }
              # binding.pry if ret.length > 0 and @interface.host.name == "fanout-de"
              ret
            end

            def vlans
              return [] if @interface.clazz != "device"
              inode = @interface.host.interface_graph.node_from_ref(@interface)
              inode.children.select{|link| link.link.ref.clazz == "vlan"}.map{|i| i.link.ref }
            end

            def bridges
              inode = @interface.host.interface_graph.node_from_ref(@interface)
              #inode.children.select{|link| link.link.ref.clazz == "bridge"}.map{|i| i.link.ref }
              inode.parents.select{|link| link.link.ref.clazz == "bridge"}.map{ |i| i.link.ref }
            end

            def as_string
              systemd_network = self
              Construqt::Util.render(binding, "systemd_network.erb")
            end

            def as_systemd_file
              as_string
            end

            def get_command
              nil
            end

            def get_name
              # idx = @interface.host.interfaces.values.find_index(@interface)
              "#{name}.network"
            end

            def is_enable
              true
            end

            def get_skip_content
              false
            end

            def commit(result)
              result.add(self, as_string,
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
              @interfaces[iface.name] ||= SystemdNetwork.new(iface)
            end

            def networks
              @interfaces.values
            end

            def commit
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              @interfaces.values.each do |sysnet|
                next unless sysnet.interface.startup?
                sysnet.commit(result)
              end
            end


            # def networks(result)
            #   result.host.interfaces.values.map do |iface|
            #     get(iface)
            #   end
            # end
            #
            # def commit
            #   result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
            #   networks(result).each do |network|
            #     network.commit(result)
            #   end
            # end
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
