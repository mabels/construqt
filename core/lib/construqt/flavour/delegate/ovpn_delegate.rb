module Construqt
  module Flavour
    module Delegate

      class OpvnDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::OPENVPN
        def initialize(opvn)
          self.delegate = opvn
        end

        def _ident
          "Opvn_#{self.host.name}_#{self.name}"
        end

        def network
          self.delegate.network
        end
      end
    end
  end
end
