module Construqt
  module Flavour
    module Delegate

      class GreDelegate
        include Delegate
        # include Member
        include InterfaceNode
        COMPONENT = Construqt::Resources::Component::UNREF
        def initialize(gre)
          self.delegate = gre
          self.init_node()
        end

        def create_interfaces(endpoint)
          self.delegate.create_interfaces(endpoint)
        end

        def _ident
          "Gre_#{self.host.name}_#{self.name}"
        end

        def cfg
          self.delegate.cfg
        end
      end
    end
  end
end
