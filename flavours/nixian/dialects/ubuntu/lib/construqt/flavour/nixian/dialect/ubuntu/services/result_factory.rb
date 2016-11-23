module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Services
            class ResultAction
              attr_reader :host
              def initialize(host)
                @host = host
              end
            end
            class ResultFactory

              attr_reader :machine
              def initialize(service_factory)
                @machine = service_factory.machine
                  .service_type(Construqt::Flavour::Nixian::Services::Result)
                  .result_type(Construqt::Flavour::Nixian::Dialect::Ubuntu::Result)
              end
              def produce(host, srv_inst, ret)
                ResultAction.new(host)
              end
            end
          end
        end
      end
    end
  end
end
