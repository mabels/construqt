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

        class RadvdAction
        end

        class RadvdFactory
          attr_reader :machine
          def initialize(service_factory)
            @machine = service_factory.machine
              .service_type(Radvd)
          end

          def produce(host, srv_inst, ret)
            RadvdAction.new
          end

        end
      end
    end
  end
end
