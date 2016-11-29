module Construqt
  module Flavour
    module Nixian
      module Services
        module BgpStartStop
          class Service
            attr_reader :name
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
