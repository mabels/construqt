module Construqt
  module Flavour
    module Nixian
      module Services
        class IpsecStartStop
          attr_reader :name
        end

        class IpsecStartStopAction
        end

        class IpsecStartStopFactory
          attr_reader :machine
          def initialize(service_factory)
            @machine = service_factory.machine
              .service_type(IpsecStartStop)
          end

          def produce(host, srv_inst, ret)
            IpsecStartStopAction.new
          end

        end
      end
    end
  end
end
