module Construqt
  module Flavour
    class Mikrotik

      class Wlan < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def stereo_type
          master_if ? 'WlanSlave' : 'Wlan'
        end

        def wireless_security_profile(host, iface)
          # !((name=sec-wlan1)
          default = {
            'authentication-types' => Schema.string.default('wpa-psk,wpa2-psk'),
            'management-protection' => Schema.identifier.default('allowed'),
            'mode' => Schema.identifier.default('dynamic-keys'),
            'supplicant-identity' => Schema.identifier.default(host.name),
            'name' => Schema.identifier.required.key,
            'wpa-pre-shared-key' => Schema.string.required,
            'wpa2-pre-shared-key' => Schema.string.required
          }
          host.delegate.result.render_mikrotik(default, {
                                        'no_auto_disable' => true,
                                        'authentication-types' => iface.authentication_types,
                                        'management-protection' => iface.management_protection,
                                        'supplicant-identity' => iface.supplicant_identity,
                                        'name' => "sec-#{iface.name}",
                                        'wpa-pre-shared-key' => iface.psk,
                                        'wpa2-pre-shared-key' => iface.psk
                                      }, 'interface', 'wireless', 'security-profiles')
        end

        def wireless_vap(host, iface)
          return unless iface.master_if
          default = {
            'mac-address' => Schema.string,
            'master-interface' => Schema.identifier.required,
            'name' => Schema.identifier.required.key,
            'security-profile' => Schema.identifier.required,
            'ssid' => Schema.identifier.required.key,
            'vlan-id' => Schema.int.required.key,
            'vlan-mode' => Schema.identifier.default('use-tag')
          }
          host.delegate.result.render_mikrotik(default, {
                                        'mac-address' => iface.mac_address,
                                        'master-interface' => iface.master_if.name,
                                        'name' => iface.name,
                                        'security-profile' => "sec-#{iface.name}",
                                        'ssid' => iface.ssid,
                                        'vlan-id' => iface.vlan_id,
                                        'vlan-mode' => iface.vlan_mode
                                      }, 'interface', 'wireless')
        end

        def wireless_if(host, iface)
          return if iface.master_if
          default = {
            'default-name' => Schema.identifier.required.key.noset,
            'band' => Schema.string.default('2ghz-B/G/N'),
            'channel-width' => Schema.string.default('20mhz'),
            'country' => Schema.string.default('germany'),
            'frequency' => Schema.string.default('auto'),
            'frequency-mode' => Schema.string.default('regulatory-domain'),
            'mode' => Schema.string.default('ap-bridge'),
            'rx-chain' => Schema.string.default('0'),
            'tx-chain' => Schema.string.default('0'),
            'ssid' => Schema.string.required,
            'security-profile' => Schema.string.required,
            'hide-ssid' => Schema.boolean.default(false)
          }
          host.delegate.result.render_mikrotik_set_by_key(default, {
                                                   'default-name' => iface.default_name,
                                                   'band' => iface.band,
                                                   'channel-width' => iface.channel_width,
                                                   'country' => iface.country,
                                                   'frequency' => iface.frequency,
                                                   'frequency-mode' => iface.frequency_mode,
                                                   'mode' => iface.mode,
                                                   'rx-chain' => iface.rx_chain,
                                                   'tx-chain' => iface.tx_chain,
                                                   'ssid' => iface.ssid,
                                                   'security-profile' => "sec-#{iface.name}",
                                                   'hide-ssid' => iface.hide_ssid
                                                 }, 'interface', 'wireless')
        end

        def build_config(host, iface, node)
          # binding.pry if iface.default_name.nil? || iface.default_name.empty?
          iface = iface.delegate

          wireless_security_profile(host, iface)
          wireless_vap(host, iface)
          wireless_if(host, iface)

          Interface.build_config(host, iface, node)
        end
      end
    end
  end
end
