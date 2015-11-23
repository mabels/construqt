module Construqt
  module Flavour
    module Delegate


      class VlanDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::UNREF
        def initialize(vlan)
          self.delegate = vlan
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
