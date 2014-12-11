module Construqt
  module Flavour
    module Ciscian
      module DlinkDgs15xx



        class HostNameVerb < PatternBasedVerb
          def self.section
            "snmp-server name"
          end

          def self.find_regex(variable)
            {
              "name" => "(.*)"
            }[variable]
          end

          def self.patterns
            ["snmp-server name {+name}"]
          end
        end

        class MtuVerb < PatternBasedVerb
          def self.section
            "max-rcv-frame-size"
          end

          def self.find_regex(variable)
            {
              "frame-size" => "(.*)"
            }[variable]
          end

          def self.patterns
            ["max-rcv-frame-size {+framesize}"]
          end
        end

        class SwitchPortTrunkAllowedVlan < PatternBasedVerb
          def self.section
            "switchport trunk allowed vlan"
          end

          def self.patterns
            ["no switchport trunk allowed vlan", "switchport trunk allowed vlan {=vlans}"]
          end
        end

        class ChannelGroupVerb < PatternBasedVerb
          def self.section
            "channel-group"
          end

          def always_select_empty_pattern
            true
          end

          def self.patterns
            ["no channel-group", "channel-group {+channel} mode active"]
          end
        end

        class EnablePasswordVerb < SingleValueVerb
          def self.section
            "enable password level"
          end

          def self.patterns
            ["no channel-group", "enable password level {+admin} {+level} {+pw_hash}"]
          end
        end

        class UserNamePasswordVerb < SingleValueVerb
          def self.section
            "user XXXXX password"
          end

          def self.patterns
          end
        end

        class UserNamePrivilegeVerb < SingleValueVerb
          def self.section
            "user XXXX privilege"
          end

          def self.patterns
          end
        end

        class PasswordVerb < SingleValueVerb
          def self.section
            "password"
          end

          def self.patterns
          end
        end

        class Ipv4RouteVerb < PatternBasedVerb
          def self.section
            "ip route"
          end

          def group?
            false
          end

          def self.find_regex(variable)
            {
              "routedefs" => "(\\S+\\s+\\S+\\s+\\S+)"
            }[variable]
          end

          def self.patterns
            ["no ip route {-routedefs}", "ip route {+routedefs}"]
          end
        end

        class IpHttpServerVerb < SingleValueVerb
          def self.parse_line(line, lines, section, result)
            regexp = /^\s*((no|) ip http server)$/
            if (line.to_s.strip =~ regexp)
              section.add(line.to_s, Ciscian::SingleValueVerb)
              return true
            end
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
            @result.add("interface #{expand_device_name(device)}", NestedSection) do |section|
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

          def is_virtual?(line)
            line.start_with?("vlan") || line.include?("port-channel")
          end

          def parse_line(line, lines, section, result)
            [
              WtfEnd,
              ConfigureTerminal,
              Line,
              Comment,
              HostNameVerb,
              MtuVerb,
              SwitchPortTrunkAllowedVlan,
              ChannelGroupVerb,
              Ipv4RouteVerb,
              IpHttpServerVerb
            ].find do |i|
              i.parse_line(line, lines, section, result)
            end
          end

          def sort_section_keys(keys)
            return keys.sort do |a,b|
              a = a.to_s
              b = b.to_s
              match_a=/^(.*[^\d])(\d+)$/.match(a)||[nil,a,1]
              match_b=/^(.*[^\d])(\d+)$/.match(b)||[nil,b,1]
              #puts match_a, match_b, a, b
              ret=0
              ret = rate_higher("vlan", match_a[1], match_b[1]) if ret==0
              ret = rate_higher("interface port-channel", match_a[1], match_b[1]) if ret==0
              ret = rate_higher("interface vlan", match_a[1], match_b[1]) if ret==0
              ret = match_a[1]<=>match_b[1] if ret==0
              ret = match_a[2].to_i<=>match_b[2].to_i if ret==0
              ret
            end
          end

          def rate_higher(prefix, a, b)
            return a.start_with?(prefix) ^ b.start_with?(prefix) ? (a.start_with?(prefix) ? -1 : 1) : 0
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
            [
              "aaa",
              "service password-encryption",
              "no ip http server",
              "debug reboot on-error",
              "no debug enable"
            ].each do |verb|
              @result.add(verb, Ciscian::SingleValueVerb)
            end

            @result.add("snmp-server name").add(@result.host.name)
            @result.host.interfaces.values.each do |iface|
              next unless iface.delegate.address
              iface.delegate.address.routes.each do |route|
                ip = route.dst.ipv6? ? "ipv6" : "ip"
                @result.add("#{ip} route #{route.dst.to_string.upcase} vlan#{iface.delegate.vlan_id} #{route.via.to_s.upcase}", Ciscian::SingleValueVerb)
              end
            end
          end

          def add_device(device)
            @result.add("interface #{expand_device_name(device)}", NestedSection) do |section|
              section.add("flowcontrol").add("off")
              section.add("max-rcv-frame-size").add(device.delegate.mtu)
              section.add("snmp trap").add("link-status")
              section.add("switchport mode").add("trunk")
            end
          end

          def add_bond(bond)
            bond.interfaces.each do |iface|
              @result.add("interface #{expand_device_name(iface)}", NestedSection) do |section|
                section.add("channel-group", ChannelGroupVerb).add({"{+channel}" => [bond.name[2..-1]]})
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
                  section.add("ip address").add(vlan.delegate.address.first_ipv4.to_string.upcase)
                elsif vlan.delegate.address.dhcpv4?
                  section.add("ip address").add("dhcp-bootp")
                end
                if vlan.delegate.address.first_ipv6
                  section.add("ipv6 address").add(vlan.delegate.address.first_ipv6.to_string.upcase)
                elsif vlan.delegate.address.dhcpv6?
                  section.add("ipv6 address").add("dhcp-bootp")
                end
              end
            end

            vlan_id=vlan.delegate.vlan_id
            vlan.interfaces.each do |iface|
              @result.add("interface #{expand_device_name(iface)}", NestedSection) do |section|
                section.add("switchport trunk allowed vlan", Ciscian::RangeVerb).add(vlan_id)
                unless iface.template.is_tagged?(vlan_id)
                  section.add("switchport trunk native vlan").add(vlan_id)
                end
              end
            end
          end
        end

        Construqt::Flavour::Ciscian.add_dialect(Dialect)
      end
    end
  end
end
