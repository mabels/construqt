module Construqt
  module Flavour
    module Delegate

      class BondDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::UNREF
        def initialize(bond)
          self.delegate = bond
        end

        def _ident
          "Bond_#{self.host.name}_#{self.name}"
        end

        def interfaces
          self.delegate.interfaces
        end
      end
    end
  end
end
