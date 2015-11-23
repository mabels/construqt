module Construqt
  module Flavour
    module Delegate

      class IpsecVpnDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::IPSEC
        def initialize(ipsecvpn)
          self.delegate = ipsecvpn
        end

        def left_interface
          self.delegate.left_interface
        end

        def ipv6_proxy
          self.delegate.ipv6_proxy
        end

        def right_address
          self.delegate.right_address
        end

        def auth_method
          self.delegate.auth_method
        end

        def users
          self.delegate.users
        end

        def leftcert
          self.delegate.leftcert
        end

        def leftpsk
          self.delegate.leftpsk
        end

        def _ident
          "IpsecVpn_#{self.host.name}_#{self.name}"
        end
      end
    end
  end
end
