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

        class ConntrackDImpl
          attr_reader :service_type
          def initialize
            @service_type = ConntrackD
          end

          def attach_service(service)
            @service = service
          end
        end
      end
    end
  end
end
