module Construqt
  module Flavour
    module Nixian
      module Services
        class IpsecStartStop
          attr_reader :name
        end

        class IpsecStartStopImpl
          attr_reader :service_type
          def initialize
            @service_type = IpsecStartStop
          end

          def attach_service(service)
            @service = service
          end
        end
      end
    end
  end
end
