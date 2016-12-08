

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class LinkMtuUpDown
            attr_reader :mtu, :ifname
            def initialize(mtu, ifname)
              @mtu = mtu
              @ifname = ifname
            end
          end
          add(LinkMtuUpDown)
        end
      end
    end
  end
end
