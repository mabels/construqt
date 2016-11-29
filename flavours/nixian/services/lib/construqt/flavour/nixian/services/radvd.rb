module Construqt
  module Flavour
    module Nixian
      module Services
        module Radvd
          class Service
            include Construqt::Util::Chainable
            attr_accessor :servers, :name, :services
            chainable_attr :adv_autonomous
            def initialize(name)
              self.name = name
            end
          end

          class Action
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
        end
      end
    end
  end
end
