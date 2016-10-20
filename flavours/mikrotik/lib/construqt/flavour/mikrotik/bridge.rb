module Construqt
  module Flavour
    class Mikrotik
      class Bridge < OpenStruct
        include Construqt::Cables::Plugin::Multiple
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface, node)
          iface = iface.delegate
          default = {
            'auto-mac' => Schema.boolean.default(true),
            'mtu' => Schema.int.required,
            'priority' => Schema.int.default(57_344),
            'name' => Schema.identifier.required.key
          }
          host.result.render_mikrotik(default, {
                                        'mtu' => iface.mtu,
                                        'name' => iface.name,
                                        'priority' => iface.priority
                                      }, 'interface', 'bridge')
          iface.interfaces.each do |port|
            host.result.render_mikrotik({
                                          'bridge' => Schema.identifier.required.key,
                                          'interface' => Schema.identifier.required.key
                                        }, {
                                          'interface' => port.name,
                                          'bridge' => iface.name
                                        }, 'interface', 'bridge', 'port')
          end
          Interface.build_config(host, iface, node)
        end
      end
    end
  end
end
