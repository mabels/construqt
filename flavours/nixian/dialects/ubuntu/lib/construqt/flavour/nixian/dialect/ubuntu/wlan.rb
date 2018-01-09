require 'openssl'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Wlan
            include BaseDevice
            include Construqt::Cables::Plugin::Single
            attr_reader :master_if, :ssid, :psk, :vlan_id, :band, :channel_width
            attr_reader :country, :mode, :rx_chain, :tx_chain, :hide_ssid
            def initialize(cfg)
              base_device(cfg)
              @ssid = cfg['ssid']
              @psk = cfg['psk']
              @vlan_id = cfg['vlan_id']
              @band = cfg['band']
              @master_if = cfg['master_if']
              @channel_width = cfg['channel_width']
              @country = cfg['country']
              @mode = cfg['mode']
              @rx_chain = cfg['rx_chain']
              @tx_chain = cfg['tx_chain']
              @hide_ssid = cfg['hide_ssid']
            end

            def build_config(host, wlan, node)
              wlan_delegate = wlan.delegate

              result = host.result_types.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              result.add(Wlan, Util.render(binding, "wlan_wpa_supplicant.conf.erb"),
                Construqt::Resources::Rights.root_0600,
                'etc', 'network', "#{@name}-wpa_supplicant.conf")

              mac_address = wlan_delegate.mac_address || Construqt::Util.generate_mac_address_from_name("#{host.name} #{wlan_delegate.name}")
              up_downer = host.result_types.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
              up_downer.add(wlan_delegate, Tastes::Entities::Wlan.new(mac_address))
              Device.build_config(host, wlan, node)
            end
          end
        end
      end
    end
  end
end
