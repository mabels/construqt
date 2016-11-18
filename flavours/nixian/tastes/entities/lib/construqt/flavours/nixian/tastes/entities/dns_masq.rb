

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class DnsMasq
            attr_reader :iface, :ifname
            def initialize(iface, ifname)
              @iface = iface
              @ifname = ifname
            end
          end
          add(DnsMasq)
        end
      end
    end
  end
end
