

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class IpSecConnect
            attr_reader :name
            def initialize(name)
              @name = name
            end
          end
          add(IpSecConnect)
        end
      end
    end
  end
end
