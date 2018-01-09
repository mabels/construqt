

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class IpSecConnect
            attr_reader :name, :endpoint
            def initialize(name, endpoint)
              @name = name
              @endpoint = endpoint
            end
          end
          add(IpSecConnect)
        end
      end
    end
  end
end
