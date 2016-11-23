module Construqt
  module Flavour
    module Nixian
      module Services
        class ConntrackD
          attr_accessor :name, :services
          def initialize(name)
            self.name = name
          end
        end

        class ConntrackDAction
        end

        class ConntrackDFactory
          attr_reader :machine
          def initialize(service_factory)
            @machine = service_factory.machine
              .service_type(ConntrackD)
          end

          def produce(host, srv_inst, ret)
            ConntrackDAction.new
          end
        end
      end
    end
  end
end
