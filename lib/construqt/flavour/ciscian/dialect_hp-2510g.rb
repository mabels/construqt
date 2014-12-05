module Construqt
  module Flavour
    module Ciscian
      class Hp2510g
        def self.name
          'hp-2510g'
        end

        def initialize(result)
          @result=result
        end

        def commit
        end

        def expand_vlan_device_name(device)
          expand_device_name(device, { "po" => "Trk%s", "ge" => "%s" })
        end

        def expand_device_name(device, map={ "po" => "Trk%s", "ge" => "ethernet %s" })
          return device.delegate.dev_name if device.delegate.dev_name
          pattern = map[device.name[0..1]]
          throw "device not expandable #{device.name}" unless pattern
          pattern%device.name[2..-1]
        end

        def add_host(host)
          @result.add("hostname", Ciscian::SingleValueVerb).add(@result.host.name)
          @result.add("max-vlans", Ciscian::SingleValueVerb).add(64)
          @result.add("snmp-server community \"public\" Unrestricted", Ciscian::SingleValueVerb)
          @result.host.interfaces.values.each do |iface|
            next unless iface.delegate.address
            iface.delegate.address.routes.each do |route|
              @result.add("ip route #{route.dst.to_s} #{route.dst.netmask} #{route.via.to_s}", Ciscian::SingleValueVerb)
            end
          end
        end

        def add_device(device)
        end

        def add_bond(bond)
          @result.add("trunk", TrunkVerb).add("{+ports}" => bond.interfaces.map{|i| i.delegate.number }, "{*channel}" => bond.delegate.number)
        end

        def add_vlan(vlan)
          @result.add("vlan #{vlan.delegate.vlan_id}") do |section|
            next unless vlan.delegate.description && !vlan.delegate.description.empty?
            throw "vlan name too long, max 32 chars" if vlan.delegate.description.length > 32
            section.add("name", Ciscian::SingleValueVerb).add(vlan.delegate.description)
            vlan.interfaces.each do |port|

              section.add({
                            true => "tagged",
                            false => "untagged"
              }[port.template.is_tagged?(vlan.vlan_id)], Ciscian::RangeVerb).add(expand_vlan_device_name(port))
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

        def parse_line(line, lines, section, result)
          [TrunkVerb, Tagged
          ].find do |i|
            i.parse_line(line, lines, section, result)
          end
        end

        def clear_interface(line)
          line.to_s.split(/\s+/).map do |i|
            split = /^([^0-9]+)([0-9].*)$/.match(i)
            split ? split[1..-1] : i
          end.flatten.join(' ')
        end

        def block_end?(line)
          ['end','exit'].include?(line.strip)
        end


        class Tagged < PatternBasedVerb
          def self.section
            "tagged"
          end

          def self.patterns
            ["tagged {+ports}", "no tagged {-ports}", "untagged {+uports}", "no untagged {-uports}"]
          end
        end

        class TrunkVerb < PatternBasedVerb
          def self.section
            "trunk"
          end

          def self.patterns
            ["no trunk {-ports}", "trunk {+ports} Trk{*channel} Trunk"]
          end
        end
      end

      Construqt::Flavour::Ciscian.add_dialect(Hp2510g)
    end
  end
end
