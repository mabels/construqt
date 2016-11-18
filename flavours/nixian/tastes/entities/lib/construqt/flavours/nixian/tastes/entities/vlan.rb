

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class Vlan
            def initialize()
            end

            def split_name(iface)
              vlan = iface.name.split('.')
              throw "vlan name not valid if.# => #{iface.name}" if vlan.length != 2 ||
                !vlan.first.match(/^[0-9a-zA-Z]+$/) ||
                !vlan.last.match(/^[0-9]+/) ||
                !(1 <= vlan.last.to_i && vlan.last.to_i < 4096)
              vlan
            end

            def vlan_id(iface)
              split_name(iface).last
            end

            def dev_name(iface)
              split_name(iface).first
            end
          end
          add(Vlan)
        end
      end
    end
  end
end
