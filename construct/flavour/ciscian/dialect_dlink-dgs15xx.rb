module Construct
  module Flavour
    module Ciscian
      class DlinkDgs15xx
        def self.name
          'dlink-dgs15xx'
        end

        def initialize(result)
          @result=result
        end

        def add_device(device)
          @result.add("interface #{device.name}") do |section|
            section.add("flowcontrol").add("off")
            section.add("max-rcv-frame-size").add(device.delegate.mtu)
            section.add("snmp trap").add("link-status")
            section.add("switchport mode").add("trunk")
          end
        end

        def add_vlan(vlan)
          @result.add("vlan #{vlan.delegate.vlan_id}") do |section|
            section.add("name").add(vlan.delegate.description)
          end

          vlan_id=vlan.delegate.vlan_id
          vlan.interfaces.each do |iface|
            @result.add("interface #{iface.name}") do |section|
              if iface.template.is_tagged?(vlan_id)
                section.add("switchport trunk allowed vlan", Ciscian::RangeVerb).add(vlan_id)
              else
                section.add("switchport trunk native vlan").add(vlan_id)
              end
            end
          end
        end
      end

      Construct::Flavour::Ciscian.add_dialect(DlinkDgs15xx)
    end
  end
end
