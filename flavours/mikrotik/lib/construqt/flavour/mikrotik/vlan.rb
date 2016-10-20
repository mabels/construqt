module Construqt
  module Flavour
    class Mikrotik
      class Vlan < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface, node)
          iface = iface.delegate
          default = {
            'interface' => Schema.identifier.required,
            'mtu' => Schema.int.required,
            'name' => Schema.identifier.required.key,
            'vlan-id' => Schema.int.required
          }
          iface.interfaces.each do |vlan_iface|
            host.result.render_mikrotik(default, {
                                          'interface' => vlan_iface.name,
                                          'mtu' => iface.mtu,
                                          'name' => iface.name,
                                          'vlan-id' => iface.vlan_id
                                        }, 'interface', 'vlan')
          end
          Interface.build_config(host, iface, node)
        end
      end
    end
  end
end
