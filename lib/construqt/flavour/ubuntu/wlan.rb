module Construqt
  module Flavour
    module Ubuntu
      class Wlan < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, wlan)
          wlan_delegate = wlan.delegate

          mac_address = wlan_delegate.mac_address || Construqt::Util.generate_mac_address_from_name("#{host.name} #{wlan_delegate.name}")
          host.result.etc_network_interfaces.get(wlan_delegate).lines.add(<<BOND)
wpa-driver wext
wpa-ssid #{wlan_delegate.ssid}
wpa-ap-scan 1
wpa-proto RSN
wpa-pairwise CCMP
wpa-group CCMP
wpa-key-mgmt WPA-PSK
wpa-psk #{OpenSSL::PKCS5.pbkdf2_hmac_sha1(wlan_delegate.psk, wlan_delegate.ssid, 4096, 32).bytes.to_a.map{|i| "%02x"%i}.join("")}
BOND
          Device.build_config(host, wlan)
        end
      end
    end
  end
end
