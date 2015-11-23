module Construqt
  module Flavour
    module Delegate

      class IpsecDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::IPSEC
        def initialize(ipsec)
          self.delegate = ipsec
        end

        def host
          self.delegate.host
        end

        def firewalls
          self.delegate.firewalls
        end

        def my
          self.delegate.my
        end

        def remote
          self.delegate.remote
        end

        def other=(a)
          self.delegate.other = a
        end

        def other
          self.delegate.other
        end

        def cfg=(a)
          self.delegate.cfg = a
        end

        def cfg
          self.delegate.cfg
        end

        def any
          self.delegate.any
        end

        def sourceip
          self.delegate.sourceip
        end

        def interface=(a)
          self.delegate.interface = a
        end

        def interface
          self.delegate.interface
        end

        def _ident
          "Ipsec_#{cfg.lefts.first.interface.name}_#{cfg.rights.first.interface.name}"
        end
      end
    end
  end
end
