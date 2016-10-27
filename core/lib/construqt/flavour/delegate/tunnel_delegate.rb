module Construqt
  module Flavour
    module Delegate


      class TunnelDelegate
        include Delegate
        # include Member
        include InterfaceNode
        COMPONENT = Construqt::Resources::Component::UNREF
        def initialize(vlan)
          self.delegate = vlan
          self.init_node()
        end

        def _ident
          "Tunnel_#{self.host.name}_#{self.name}"
        end
      end
    end
  end
end
