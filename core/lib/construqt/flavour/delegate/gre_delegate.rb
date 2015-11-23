module Construqt
  module Flavour
    module Delegate

      class GreDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::UNREF
        def initialize(gre)
          self.delegate = gre
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
