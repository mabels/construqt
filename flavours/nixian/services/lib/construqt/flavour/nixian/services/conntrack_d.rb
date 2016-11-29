module Construqt
  module Flavour
    module Nixian
      module Services
        module ConntrackD
          class Service
            attr_accessor :name, :services
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
                .depend(Result::Service)
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
