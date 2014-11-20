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

        def expand_device_name(device)

          return device.delegate.dev_name if device.delegate.dev_name
          pattern = (({
                        "po" => "port-channel %s",
                        "ge" => "ethernet 1/0/%s",
                        "te" => "ethernet 1/0/%s"
          })[device.name[0..1]])
          throw "device not expandable #{device.name}" unless pattern
          pattern%device.name[2..-1]
        end

        def commit
        end

        def add_device(device)
          @result.add("interface #{expand_device_name(device)}") do |section|
            section.add("flowcontrol").add("off")
            section.add("max-rcv-frame-size").add(device.delegate.mtu)
            section.add("snmp trap").add("link-status")
            section.add("switchport mode").add("trunk")
          end
        end

        def add_bond(bond)
          bond.interfaces.each do |iface|
            @result.add("interface #{expand_device_name(iface)}") do |section|
              section.add(ChannelGroupVerb).add(bond)
            end
          end
        end

        def add_vlan(vlan)
          @result.add("vlan #{vlan.delegate.vlan_id}") do |section|
            next unless vlan.delegate.description && !vlan.delegate.description.empty?
            throw "vlan name too long, max 32 chars" if vlan.delegate.description.length > 32
            section.add("name").add(vlan.delegate.description)
          end

          vlan_id=vlan.delegate.vlan_id
          vlan.interfaces.each do |iface|
            @result.add("interface #{expand_device_name(iface)}") do |section|
              if iface.template.is_tagged?(vlan_id)
                section.add("switchport trunk allowed vlan", Ciscian::RangeVerb).add(vlan_id)
              else
                section.add("switchport trunk native vlan").add(vlan_id)
              end
            end
          end
        end
      end

      class ChannelGroupVerb < GenericVerb
        def self.section_key
          "channel-group"
        end
        def add(bond)
          @bond=bond
        end
        def serialize
          "  channel-group #{@bond.name[2..-1]} mode #{@bond.delegate.mode || 'active'}"
        end
      end

      Construct::Flavour::Ciscian.add_dialect(DlinkDgs15xx)
    end
  end
end
