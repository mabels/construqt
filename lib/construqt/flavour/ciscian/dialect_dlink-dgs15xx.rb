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

          def self.patterns
            ["no channel-group", "channel-group {+channel} mode active"]
          end
        end

        class Ipv4RouteVerb < PatternBasedVerb
          def self.section
            "ip route"
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
              SwitchPortTrunkAllowedVlan,
              ChannelGroupVerb,
              Ipv4RouteVerb
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
#            ["aaa",
#             "autoconfig",
#             ["clock timezone", "+ 1"],
#             "no clock summer-time"
#             "sntp interval 720"
#             "ddp report-timer 30",
#             "debug"
#             "debug reboot"
#             "dim"
#             "enable password XXXXXXXXXXXXXXXX"
#             "ignore"
#             "instance 16 vlans"
  #             no power-saving link-detection
  #             no dim led
  #             no power-saving hibernation
  #             no power-saving dim-led
  #             no power-saving port-shutdown
#
#
#             "ddp"
#             "no power-saving eee"
#             "no snmp-server trap-sending"
#             "no speed"
#             "spanning-tree guard"
#             "spanning-tree mst hello-time"
#
#
#            "ip arp gratuitous"
#            "ip dhcp relay information option format circuit-id default"
#            "ip dhcp relay information option format remote-id default"
#            "ip dhcp relay information policy replace"
#            "ip domain"
#            "ip http service-port"
#            "ip http timeout-policy idle"
#            "ip ssh"
#            "ip telnet"
#            "ip telnet service-port"
#            "port-channel load-balance"
#            "power-saving"
#            "service"
#
#            "snmp-server community private  view CommunityView"
#            "snmp-server community public  view CommunityView"
#            "snmp-server contact"
#            "snmp-server enable traps rmon falling-alarm"
#            "snmp-server enable traps snmp rising-alarm"
#            "snmp-server engineID local"
#            "snmp-server group initial"
#            "snmp-server group initial v3  noauth read restricted notify"
#            "snmp-server group private v1 read CommunityView write CommunityView notify"
#            "snmp-server group private v2c read CommunityView write CommunityView notify"
#            "snmp-server group public v1 read CommunityView notify"
#            "snmp-server group public v2c read CommunityView notify"
#            "snmp-server location"
#            "snmp-server response"
#            "snmp-server service-port"
#            "snmp-server user initial"
#            "snmp-server user initial initial"
#            "snmp-server view CommunityView 1"
#            "snmp-server view CommunityView 1.3.6.1.6.3"
#            "snmp-server view CommunityView 1.3.6.1.6.3.1"
#            "snmp-server view restricted 1.3.6.1.2.1.1"
#            "snmp-server view restricted 1.3.6.1.2.1.11"
#            "snmp-server view restricted 1.3.6.1.6.3.10.2.1"
#            "snmp-server view restricted 1.3.6.1.6.3.11.2.1"
#            "snmp-server view restricted 1.3.6.1.6.3.15.1.1"
#            "sntp"
#            "sntp interval"
#            "spanning-tree mode"
#            "spanning-tree mst"
#            "ssh user root authentication-method"
#            "username root password 7"
#            "username root privilege"
#


            @result.add("snmp-server name", Ciscian::SingleValueVerb).add(@result.host.name)
            @result.host.interfaces.values.each do |iface|
              next unless iface.delegate.address
              iface.delegate.address.routes.each do |route|
                ip = route.dst.ipv6? ? "ipv6" : "ip"
                @result.add("#{ip} route #{route.dst.to_string} vlan#{iface.delegate.vlan_id} #{route.via.to_s}", Ciscian::SingleValueVerb)
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

        Construqt::Flavour::Ciscian.add_dialect(Dialect)
      end
    end
  end
end
