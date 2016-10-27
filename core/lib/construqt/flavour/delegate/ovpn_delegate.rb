module Construqt
  module Flavour
    module Delegate

      class OpvnDelegate
        include Delegate
        include InterfaceNode
        COMPONENT = Construqt::Resources::Component::OPENVPN
        def initialize(opvn)
          self.delegate = opvn
          self.init_node().parents([opvn.listen])
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
