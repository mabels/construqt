module Construqt
  module Flavour
    module Delegate

      class BridgeDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::UNREF
        def initialize(bridge)
          self.delegate = bridge
        end

        def _ident
          "Bridge_#{self.host.name}_#{self.name}"
        end

        def interfaces
          self.delegate.interfaces
        end
      end
    end
  end
end
