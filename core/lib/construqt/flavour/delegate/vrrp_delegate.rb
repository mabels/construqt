module Construqt
  module Flavour
    module Delegate

      class VrrpDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::VRRP
        def initialize(vrrp)
          #binding.pry
          self.delegate = vrrp
        end

        def _ident
          "Vrrp_#{self.name}_#{self.delegate.interfaces.map{|i| "#{i.host.name}_#{i.name}"}.join("_")}"
        end
      end
    end
  end
end
