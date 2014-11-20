module Construct
  module Flavour
    module Ciscian
      class Hp2510g
        def self.name
          'hp-2510g'
        end

        #hostname "ProCurve Switch 2510G-48"
        #max-vlans 64
        #
        #vlan 1
        #name "DEFAULT_VLAN"
        # untagged 1-48
        #  ip address dhcp-bootp
        #   exit

        def initialize(result)
          @result=result
        end

        def commit
          @result.add("hostname", Ciscian::SingleVerb).add(@result.host.name)
          @result.add("max-vlans", Ciscian::SingleVerb).add(64)
          @result.add("snmp-server community \"public\" Unrestricted", Ciscian::SingleVerb)
          @result.host.interfaces.values.each do |iface|
            next unless iface.delegate.address
            iface.delegate.address.routes.each do |route|
              @result.add("ip route #{route.dst.to_s} #{route.dst.netmask} #{route.via.to_s}", Ciscian::SingleVerb)
            end
          end
        end

        def expand_device_name(device)
          return device.delegate.dev_name if device.delegate.dev_name
          pattern = (({
                        "po" => "Trk%s",
                        "ge" => "ethernet %s"
          })[device.name[0..1]])
          throw "device not expandable #{device.name}" unless pattern
          pattern%device.name[2..-1]
        end

        def add_device(device)
          #@result.add("interface #{expand_device_name(device)}") do |section|
          #end
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
            section.add("name", Ciscian::StringVerb).add(vlan.delegate.description)


            vlan.interfaces.each do |port|
              section.add({
                            true => "tagged",
                            false => "untagged"
              }[port.template.is_tagged?(vlan.vlan_id)], Ciscian::RangeVerb).add(port.delegate.number)
            end

            if vlan.delegate.address
              if vlan.delegate.address.first_ipv4
                section.add("ip address").add(vlan.delegate.address.first_ipv4.to_string)
              elsif vlan.delegate.address.dhcpv4?
                section.add("ip address").add("dhcp-bootp")
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

      Construct::Flavour::Ciscian.add_dialect(Hp2510g)
    end
  end
end
