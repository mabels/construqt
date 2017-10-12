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
          self.init_node().parents(self.delegate.interfaces)
        end

        def interfaces
          self.delegate.interfaces
        end

        def endpoint
          self.delegate.endpoint
        end

        def mode
          self.delegate.mode
        end

        def shortname
          self.delegate.shortname
        end

        def _ident
          "Gre_#{self.host.name}_#{self.name}"
        end
      end
    end
  end
end
