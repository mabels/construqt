require_relative 'dell/powerconnect_55xx'

module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dell

          class Factory
            def name
              "dell"
            end
            def produce(cfg)
              factory = {
                "powerconnect_55xx" => Powerconnect55xx,
              }
              throw "cfg need type" unless cfg["type"]
              throw "cfg type not found" unless factory[cfg["type"]]
              factory[cfg["type"]].new
            end
          end

        end
      end
    end
  end
end
