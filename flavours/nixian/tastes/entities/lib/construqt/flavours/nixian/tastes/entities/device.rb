

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class Device
            attr_reader :ifname
            def initialize(ifname)
              @ifname = ifname
            end
          end
          add(Device)
        end
      end
    end
  end
end
