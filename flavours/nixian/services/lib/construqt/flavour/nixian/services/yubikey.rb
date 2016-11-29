module Construqt
  module Flavour
    module Nixian
      module Services
        module Yubikey
          class Service
            include Construqt::Util::Chainable
            attr_accessor :servers, :name, :services
            chainable_attr :adv_autonomous
            def initialize(name)
              self.name = name
            end
          end

          class Factory
            attr_reader :machine
            def initialize(service_factory)
              @machine = service_factory.machine
                .service_type(Service)
            end

            def produce(host, srv_inst, ret)
              Action.new
            end
          end

          class Action
            #unless ykeys.empty?
            #  host.result.add(self, ykeys.join("\n"), Construqt::Resources::Rights.root_0644, "etc", "yubikey_mappings")
            #end

            #host.result.add(self, Construqt::Util.render(binding, "ovpn_pam.erb"), Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::OPENVPN), "etc", "pam.d", "openvpn")
          end
        end
      end
    end
  end
end
