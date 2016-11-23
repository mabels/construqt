module Construqt
  module Flavour
    module Nixian
      module Services
        class BgpStartStop
          attr_reader :name
        end

        class BgpStartStopSystemdTaste
        end
        class BgpStartStopDebianTaste
        end
        class BgpStartStopFlatTaste
        end


        class BgpStartStopFactory
          attr_reader :machine
          def initialize(service_factory)
            @machine = service_factory.machine
              .service_type(BgpStartStop)
          end

          def produce(host, srv_inst, ret)
            BgpStartStopAction.new
          end
        end

        class BgpStartStopAction

        #  def attach_service(service)
        #    @service = service
        #  end

          def entities_for_taste(taste)
            #{
            #  @taste_registry[taste.class.name.split("::").last])
            #}
          end

        end
      end
    end
  end
end
