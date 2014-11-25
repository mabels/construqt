module Construct
  module Flavour
    module Ciscian
      module DlinkDgs15xx

        class HostNameVerb
          def self.parse_line(line, lines, section, result)
            return false unless line.to_s.start_with?("snmp-server name")
            result.host.name = line.to_s.split(/\s+/)[2]
            section.add(Result::Lines::Line.new("snmp-server name", line.nr), Ciscian::SingleVerb).add(result.host.name)
            true
          end
        end

        class MtuVerb
          def self.parse_line(line, lines, section, result)
            verb = "max-rcv-frame-size"
            return false unless line.to_s.start_with?(verb)
            section.add(verb).add(line.to_s[verb.length..-1].strip.to_i)
          end
        end

        class SwitchPortTrunkAllowedVlan
          def self.parse_line(line, lines, section, result)
            verb = "switchport trunk allowed vlan"
            return false unless line.to_s.start_with?(verb)
            Util.expandRangeDefinition(line.to_s[verb.length..-1]).each do |vlan_id|
              section.add(verb, Ciscian::RangeVerb).add(vlan_id)
            end
            true
          end
        end

        class Comment
          def self.parse_line(line, lines, section, result)
            line.to_s.empty? || line.to_s.start_with?("#")
          end
        end

        class WtfEnd
          def self.parse_line(line, lines, section, result)
            section.kind_of?(Result) && ["end"].include?(line.to_s)
          end
        end

        class Line
          def self.parse_line(line, lines, section, result)
            return false unless ['line '].find{|i| line.to_s.start_with?(i) }
            section.add(line) do |_section|
              while line = lines.shift
                break if result.dialect.block_end?(line.to_s)
                result.parse_line(line, lines, _section, result)
              end
            end
            true
          end
        end

        class ConfigureTerminal
          def self.parse_line(line, lines, section, result)
            return false unless ['configure terminal'].find{|i| line.to_s.start_with?(i) }
            while line = lines.shift
              break if result.dialect.block_end?(line.to_s)
              result.parse_line(line, lines, section, result)
            end
            true
          end
        end

        class Dialect
          def self.name
            'dlink-dgs15xx'
          end

          def initialize(result)
            @result=result
          end

          def block_end?(line)
            ['end','exit'].include?(line.strip)
          end

          def add_host(host)
          end

          def add_device(device)
            @result.add("interface #{expand_device_name(device)}") do |section|
              section.add("flowcontrol").add("off")
              section.add("max-rcv-frame-size").add(device.delegate.mtu)
              section.add("snmp trap").add("link-status")
              section.add("switchport mode").add("trunk")
            end
          end

          def clear_interface(line)
            line.to_s.split(/\s+/).map do |i|
              split = /^([^0-9]+)([0-9].*)$/.match(i)
              split ? split[1..-1] : i
            end.flatten.join(' ')
          end

          def parse_line(line, lines, section, result)
            [
              WtfEnd,
              ConfigureTerminal,
              Line,
              Comment,
              HostNameVerb,
              MtuVerb,
              SwitchPortTrunkAllowedVlan
            ].find do |i|
              i.parse_line(line, lines, section, result)
            end
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
            @result.add("snmp-server name", Ciscian::SingleVerb).add(@result.host.name)
            @result.host.interfaces.values.each do |iface|
              next unless iface.delegate.address
              iface.delegate.address.routes.each do |route|
                ip = route.dst.ipv6? ? "ipv6" : "ip"
                @result.add("#{ip} route #{route.dst.to_string} vlan#{iface.delegate.vlan_id} #{route.via.to_s}", Ciscian::SingleVerb)
              end
            end
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
            @result.add("interface vlan #{vlan.delegate.vlan_id}") do |section|
              if vlan.delegate.address
                if vlan.delegate.address.first_ipv4
                  section.add("ip address").add(vlan.delegate.address.first_ipv4.to_string)
                elsif vlan.delegate.address.dhcpv4?
                  section.add("ip address").add("dhcp-bootp")
                end
                if vlan.delegate.address.first_ipv6
                  section.add("ipv6 address").add(vlan.delegate.address.first_ipv6.to_string)
                elsif vlan.delegate.address.dhcpv6?
                  section.add("ipv6 address").add("dhcp-bootp")
                end
              end
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
            ["channel-group #{@bond.name[2..-1]} mode #{@bond.delegate.mode || 'active'}"]
          end
        end

        Construct::Flavour::Ciscian.add_dialect(Dialect)
      end
    end
  end
end
