module Construqt
  module Flavour
    class Mikrotik
      class Device < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface, node)
          binding.pry if iface.default_name.nil? || iface.default_name.empty?
          iface = iface.delegate
          default = {
            'l2mtu' => Schema.int.default(1590),
            'mtu' => Schema.int.default(1500),
            'name' => Schema.identifier.default('dummy'),
            'default-name' => Schema.identifier.required.key.noset
          }
          host.delegate.result.render_mikrotik_set_by_key(default, {
                                                   'l2mtu' => iface.mtu + 80, # vlans and mpls need more space
                                                   'mtu' => iface.mtu,
                                                   'name' => iface.name,
                                                   'default-name' => iface.default_name
                                                 }, 'interface')
          Interface.build_config(host, iface, node)
        end
      end
    end
  end
end
