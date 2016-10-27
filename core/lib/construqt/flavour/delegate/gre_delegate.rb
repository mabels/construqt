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

        def create_interfaces(host, name, cfg)
          self.delegate.create_interfaces(host, name, cfg)
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
