

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class Bridge
            attr_reader :ifname
            def initialize(ifname)
              @ifname = ifname
            end
          end
          add(Bridge)
        end
      end
    end
  end
end
