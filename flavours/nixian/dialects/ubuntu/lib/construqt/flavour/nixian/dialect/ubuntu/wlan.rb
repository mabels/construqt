require 'openssl'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Wlan
            include BaseDevice
            include Construqt::Cables::Plugin::Single
            attr_reader :master_if, :ssid, :psk
            def initialize(cfg)
              base_device(cfg)
              @ssid = cfg['ssid']
              @psk = cfg['psk']
              @master_if = cfg['master_if']
            end

            def build_config(host, wlan, node)
              wlan_delegate = wlan.delegate

              host.result.add(Wlan, Util.render(binding, "wlan_wpa_supplicant.conf.erb"),
                Construqt::Resources::Rights.root_0600,
                'etc', 'network', "#{@name}-wpa_supplicant.conf")

              mac_address = wlan_delegate.mac_address || Construqt::Util.generate_mac_address_from_name("#{host.name} #{wlan_delegate.name}")
              host.result.up_downer.add(wlan_delegate, Tastes::Entities::Wlan.new(mac_address))
              Device.build_config(host, wlan, node)
            end
          end
        end
      end
    end
  end
end
