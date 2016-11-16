module Construqt
  module Flavour
    module Nixian
      module Services
        class BgpStartStop
          attr_reader :name
        end

        class BgpStartStopImpl
          attr_reader :service_type
          def initialize
            @service_type = BgpStartStop
          end

          def attach_service(service)
            @service = service
          end
        end
      end
    end
  end
end
