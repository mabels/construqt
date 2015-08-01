module Construqt
  module Flavour
    module Ubuntu
      class Vlan < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
          vlan = iface.name.split('.')
          throw "vlan name not valid if.# => #{iface.name}" if vlan.length != 2 ||
            !vlan.first.match(/^[0-9a-zA-Z]+$/) ||
            !vlan.last.match(/^[0-9]+/) ||
            !(1 <= vlan.last.to_i && vlan.last.to_i < 4096)
          Device.build_config(host, iface)
        end
      end
    end
  end
end
