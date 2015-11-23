require_relative 'dgs15xx/channel_group_verb'
require_relative 'dgs15xx/enable_password_verb'
require_relative 'dgs15xx/ipv4_route_verb'
require_relative 'dgs15xx/password_verb'
require_relative 'dgs15xx/user_name_privilege_verb'
require_relative 'dgs15xx/comment'
require_relative 'dgs15xx/host_verb'
require_relative 'dgs15xx/line'
require_relative 'dgs15xx/switch_port_trunk_allowed_vlan'
require_relative 'dgs15xx/wtf_end'
require_relative 'dgs15xx/configure_terminal'
require_relative 'dgs15xx/ip_http_server_verb'
require_relative 'dgs15xx/mtu_verb'
require_relative 'dgs15xx/user_name_password_verb'

module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink
          class Dgs15xx

              def initialize(result)
                @result = result
              end

              def block_end?(line)
                %w(end exit).include?(line.strip)
              end

              def add_host(_host)
              end

              def clear_interface(line)
                line.to_s.split(/\s+/).map do |i|
                  split = /^([^0-9]+)([0-9].*)$/.match(i)
                  split ? split[1..-1] : i
                end.flatten.join(' ')
              end

              def is_virtual?(line)
                line.start_with?('vlan') || line.include?('port-channel')
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
                keys.sort do |a, b|
                  a = a.to_s
                  b = b.to_s
                  match_a = /^(.*[^\d])(\d+)$/.match(a) || [nil, a, 1]
                  match_b = /^(.*[^\d])(\d+)$/.match(b) || [nil, b, 1]
                  # puts match_a, match_b, a, b
                  ret = 0
                  ret = Construqt::Util.rate_higher('vlan', match_a[1], match_b[1]) if ret == 0
                  ret = Construqt::Util.rate_higher('interface port-channel', match_a[1], match_b[1]) if ret == 0
                  ret = Construqt::Util.rate_higher('interface vlan', match_a[1], match_b[1]) if ret == 0
                  ret = match_a[1] <=> match_b[1] if ret == 0
                  ret = match_a[2].to_i <=> match_b[2].to_i if ret == 0
                  ret
                end
              end

              def expand_device_name(device)
                return device.delegate.dev_name if device.delegate.dev_name
                pattern = (({
                  'po' => 'port-channel %s',
                  'ge' => 'ethernet 1/0/%s',
                  'te' => 'ethernet 1/0/%s'
                })[device.name[0..1]])
                throw "device not expandable #{device.name}" unless pattern
                pattern % device.name[2..-1]
              end

              def commit
                [
                  'aaa',
                  'service password-encryption',
                  'no ip http server',
                  'debug reboot on-error',
                  'no debug enable'
                ].each do |verb|
                  @result.add(verb, Ciscian::SingleValueVerb)
                end

                @result.add('snmp-server name').add(@result.host.name)
                @result.host.interfaces.values.each do |iface|
                  next unless iface.delegate.address
                  iface.delegate.address.routes.each do |route|
                    ip = route.dst.ipv6? ? 'ipv6' : 'ip'
                    @result.add("#{ip} route #{route.dst.to_string.upcase} vlan#{iface.delegate.vlan_id} #{route.via.to_s.upcase}", Ciscian::SingleValueVerb)
                  end
                end
              end

              def add_device(device, bond = false)
                @result.add("interface #{expand_device_name(device)}", NestedSection) do |section|
                  section.add('switchport mode').add('trunk')
                  unless bond
                    section.add('flowcontrol').add('off')
                    section.add('max-rcv-frame-size').add(device.delegate.mtu)
                    section.add('snmp trap').add('link-status')
                  end
                end
              end

              def add_bond(bond)
                bond.interfaces.each do |iface|
                  @result.add("interface #{expand_device_name(iface)}", NestedSection) do |section|
                    section.add('channel-group', ChannelGroupVerb).add({ '{+channel}' => [bond.name[2..-1]] })
                  end
                end
                add_device(bond, true)
              end

              def add_vlan(vlan)
                @result.add("vlan #{vlan.delegate.vlan_id}", NestedSection) do |section|
                  next unless vlan.delegate.description && !vlan.delegate.description.empty?
                  throw 'vlan name too long, max 32 chars' if vlan.delegate.description.length > 32
                  section.add('name').add(vlan.delegate.description)
                end
                @result.add("interface vlan #{vlan.delegate.vlan_id}", NestedSection) do |section|
                  if vlan.delegate.address
                    if vlan.delegate.address.first_ipv4
                      section.add('ip address').add(vlan.delegate.address.first_ipv4.to_string.upcase)
                    elsif vlan.delegate.address.dhcpv4?
                      section.add('ip address').add('dhcp-bootp')
                    end
                    if vlan.delegate.address.first_ipv6
                      section.add('ipv6 address').add(vlan.delegate.address.first_ipv6.to_string.upcase)
                    elsif vlan.delegate.address.dhcpv6?
                      section.add('ipv6 address').add('dhcp-bootp')
                    end
                  end
                end

                vlan_id = vlan.delegate.vlan_id
                vlan.interfaces.each do |iface|
                  @result.add("interface #{expand_device_name(iface)}", NestedSection) do |section|
                    section.add('switchport trunk allowed vlan', Ciscian::RangeVerb).add(vlan_id)
                    unless iface.template.is_tagged?(vlan_id)
                      section.add('switchport trunk native vlan').add(vlan_id)
                    end
                  end
                end
              end
            end

            #Construqt::Flavour::Ciscian.add_dialect(Dgs15xx)
          end
        end
      end
    end
  end
end
