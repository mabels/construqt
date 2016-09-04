require 'openssl'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Wlan < OpenStruct
            include Construqt::Cables::Plugin::Single
            def initialize(cfg)
              super(cfg)
            end

            def build_config(host, wlan)
              wlan_delegate = wlan.delegate

              mac_address = wlan_delegate.mac_address || Construqt::Util.generate_mac_address_from_name("#{host.name} #{wlan_delegate.name}")
              host.result.etc_network_interfaces.get(wlan_delegate)
                .lines.add(Construqt::Util.render(binding, "wlan_interfaces.erb"))
              Device.build_config(host, wlan)
            end
          end
        end
      end
    end
  end
end
