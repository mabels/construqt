module Construqt
  module Flavour
    module Delegate

      class VlanDelegate
        include Delegate
        # include Member
        include InterfaceNode
        COMPONENT = Construqt::Resources::Component::UNREF
        def initialize(vlan)
          self.delegate = vlan
          self.init_node().parents(self.delegate.interfaces)
        end

        def interfaces
          self.delegate.interfaces
        end

        def vlan_id
          self.delegate.vlan_id
        end

        def _ident
          "Vlan_#{self.host.name}_#{self.name}"
        end
      end
    end
  end
end
