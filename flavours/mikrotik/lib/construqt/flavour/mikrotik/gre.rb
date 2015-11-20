module Construqt
  module Flavour
    class Mikrotik
      class Gre < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def set_interface_gre(host, cfg)
          default = {
            'name' => Schema.identifier.required.key,
            'local-address' => Schema.address.required,
            'remote-address' => Schema.address.required,
            'dscp' => Schema.identifier.default('inherit'),
            'mtu' => Schema.int.default(1476)
            #            "l2mtu"=>Scheme.int.default(65535)
          }
          host.result.render_mikrotik(default, cfg, 'interface', 'gre')
        end

        def set_interface_gre6(host, cfg)
          default = {
            'name' => Schema.identifier.required.key,
            'local-address' => Schema.address.required,
            'remote-address' => Schema.address.required,
            'keepalive' => Schema.identifiers.default(Schema::DISABLE),
            'mtu' => Schema.int.default(1456)
            #            "l2mtu"=>Schema.int.default(65535)
          }
          host.result.render_mikrotik(default, cfg, 'interface', 'gre6')
        end

        def build_config(host, iface)
          iface = iface.delegate
          # puts "iface.name=>#{iface.name}"
          # binding.pry
          # iname = Util.clean_if("gre6", "#{iface.name}")
          if iface.local.first_ipv6 && iface.remote.first_ipv6
            set_interface_gre6(host, 'name' => iface.name,
                                     'local-address' => iface.local.first_ipv6,
                                     'remote-address' => iface.remote.first_ipv6)
          else
            set_interface_gre(host, 'name' => iface.name,
                                    'local-address' => iface.local.first_ipv4,
                                    'remote-address' => iface.remote.first_ipv4)
          end
          Interface.build_config(host, iface)

          # Mikrotik.set_ipv6_address(host, "address"=>iface.address.first_ipv6.to_string, "interface" => iname)
        end
      end
    end
  end
end
