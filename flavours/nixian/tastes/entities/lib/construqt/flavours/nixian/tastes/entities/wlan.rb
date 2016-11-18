

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class Wlan
            attr_reader :mac_address
            def initialize(mac_address)
              @mac_address
            end
          end
          add(Wlan)
        end
      end
    end
  end
end
