module Construqt
  module Flavour
    class Mikrotik

      class Vrrp < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
          iface = iface.delegate
          default = {
            "interface" => Schema.identifier.required,
            "name" => Schema.identifier.key.required,
            "priority" => Schema.int.required,
            "v3-protocol" => Schema.identifier.required,
            "vrid" => Schema.int.required
          }
          host.result.render_mikrotik(default, {
            "interface" => iface.interface.name,
            "name" => iface.name,
            "priority" => iface.interface.priority,
            "v3-protocol" => "ipv6",
            "vrid" => iface.vrid
          }, "interface", "vrrp")
          Interface.build_config(host, iface)
        end
      end
      
    end
  end
end
