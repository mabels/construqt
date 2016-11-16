require_relative 'dlink/dgs15xx'

module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink

          class Factory
            def name
              "dlink"
            end
            def produce(cfg)
              factory = {
                "dgs15xx" => Dgs15xx,
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
