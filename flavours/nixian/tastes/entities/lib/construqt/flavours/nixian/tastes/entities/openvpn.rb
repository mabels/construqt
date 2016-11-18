

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class OpenVpn
            attr_reader :iface
            def initialize(iface)
              @iface = iface
            end
          end
          add(OpenVpn)
        end
      end
    end
  end
end
