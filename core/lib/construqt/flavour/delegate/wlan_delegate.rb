module Construqt
  module Flavour
    module Delegate

      class WlanDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::UNREF
        def initialize(wlan)
          self.delegate = wlan
        end

        def _ident
          "Wlan_#{self.host.name}_#{self.name}"
        end

        def stereo_type
          self.delegate.stereo_type
        end

        def master_if
          self.delegate.master_if
        end

        def vlan_id
          self.delegate.vlan_id
        end

        def psk
          self.delegate.psk
        end

        def ssid
          self.delegate.ssid
        end

        def band
          self.delegate.band
        end

        def channel_width
          self.delegate.channel_width
        end

        def country
          self.delegate.country
        end

        def mode
          self.delegate.mode
        end

        def rx_chain
          self.delegate.rx_chain
        end

        def tx_chain
          self.delegate.tx_chain
        end

        def hide_ssid
          self.delegate.hide_ssid
        end
      end
    end
  end
end
