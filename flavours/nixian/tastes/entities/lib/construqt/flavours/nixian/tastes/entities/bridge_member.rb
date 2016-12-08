

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class BridgeMember
            attr_reader :bname, :ifname
            def initialize(bname, ifname)
              @bname = bname
              @ifname = ifname
            end
          end
          add(BridgeMember)
        end
      end
    end
  end
end
