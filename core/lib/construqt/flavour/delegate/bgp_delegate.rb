module Construqt
  module Flavour
    module Delegate

      class BgpDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::BGP
        def initialize(bgp)
          self.delegate = bgp
        end

        def once(host)
          self.delegate.once(host)
        end

        def as
          self.delegate.as
        end

        def routing_table
          self.delegate.routing_table
        end

        def my
          self.delegate.my
        end

        def host
          self.delegate.host
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

        def _ident
          "Bgp_#{cfg.lefts.first.host.name}_#{cfg.lefts.first.my.name}_#{cfg.rights.first.host.name}_#{cfg.rights.first.my.name}"
        end
      end
    end
  end
end
