module Construqt
  module Flavour
    module Nixian
      module Services
        class Radvd
          include Construqt::Util::Chainable
          attr_accessor :servers, :name, :services
          chainable_attr :adv_autonomous
          def initialize(name)
            self.name = name
          end
        end

        class RadvdImpl
          attr_reader :service_type
          def initialize
            @service_type = Radvd
          end

          def attach_service(service)
            @service = service
          end

          def build_interface(host, ifname, iface, writer)
          end

        end
      end
    end
  end
end
