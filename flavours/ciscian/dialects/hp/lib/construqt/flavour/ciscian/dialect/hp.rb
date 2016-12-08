require_relative 'hp/hp2510g'
require_relative 'hp/hp2530g'

module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Hp

          class Factory
            def name
              "hp"
            end
            def produce(parent, cfg)
              factory = {
                "hp2510g" => Hp2510g,
                "hp2530g" => Hp2530g
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
