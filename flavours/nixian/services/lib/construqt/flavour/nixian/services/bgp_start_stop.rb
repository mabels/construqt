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

        class BgpStartStopImpl
          attr_reader :service_type
          def initialize
            @service_type = BgpStartStop
            @taste_registry = {
              "UpDownerSystemdTaste" => BgpStartStopSystemdTaste.new(),
              "UpDownerDebianTaste" => BgpStartStopDebianTaste.new(),
              "UpDownerFlatTaste" => BgpStartStopFlatTaste.new()
            }
          end

          def attach_service(service)
            @service = service
          end

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
