module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result

            class EtcNetworkInterfaces
              def initialize(result)
                @result = result
                @entries = {}
              end

              class Entry
                class Header
                  MODE_MANUAL = :manual
                  MODE_LOOPBACK = :loopback
                  MODE_DHCP = :dhcp
                  PROTO_INET6 = :inet6
                  PROTO_INET4 = :inet
                  AUTO = :auto
                  def mode(mode)
                    @mode = mode
                    self
                  end

                  def dhcpv4
                    @mode = MODE_DHCP
                    self
                  end

                  def dhcpv6
                    @dhcpv6 = true
                    self
                  end

                  def protocol(protocol)
                    @protocol = protocol
                    self
                  end

                  def noauto
                    @auto = false
                    self
                  end

                  def initialize(entry)
                    @entry = entry
                    @auto = true
                    @mode = MODE_MANUAL
                    @protocol = PROTO_INET4
                    @interface_name = nil
                  end

                  def interface_name(name)
                    @interface_name = name
                  end

                  def get_interface_name
                    @interface_name || @entry.iface.name
                  end

                  def commit
                    return '' if @entry.skip_interfaces?
                    ipv6_dhcp = "iface #{get_interface_name} inet6 dhcp" if @dhcpv6
                    out = <<OUT
# #{@entry.iface.clazz}
#{@auto ? "auto #{get_interface_name}" : ''}
#{ipv6_dhcp || ''}
iface #{get_interface_name} #{@protocol} #{@mode}
  up   /bin/bash /etc/network/#{get_interface_name}-up.iface
  down /bin/bash /etc/network/#{get_interface_name}-down.iface
OUT
                  end
                end

                class Lines
                  def initialize(entry)
                    @entry = entry
                    @lines = []
                    @ups = []
                    @downs = []
                  end

                  def up(block, order = 0)
                    @ups << [order, block.each_line.map(&:strip).select { |i| !i.empty? }]
                  end

                  def down(block, order = 0)
                    @downs << [order, block.each_line.map(&:strip).select { |i| !i.empty? }]
                  end

                  def add(block)
                    @lines += block.each_line.map(&:strip).select { |i| !i.empty? }
                  end

                  def write_s(component, direction, blocks)
                    @entry.result.add(self.class, <<BLOCK, Construqt::Resources::Rights.root_0755(component), 'etc', 'network', "#{@entry.header.get_interface_name}-#{direction}.iface")
#!/bin/bash
exec > >(logger -t "#{@entry.header.get_interface_name}-#{direction}") 2>&1
#{blocks.join("\n")}
exit 0
BLOCK
                    # iptables-restore < /etc/network/iptables.cfg
                    # ip6tables-restore < /etc/network/ip6tables.cfg
                  end

                  def ordered_lines(lines)
                    result = lines.inject({}) { |r, l| r[l.first] ||= []; r[l.first] << l.last; r }
                    result.keys.sort.map { |key| result[key] }.flatten
                  end

                  def commit
                    write_s(@entry.iface.class.name, 'up', ordered_lines(@ups))
                    write_s(@entry.iface.class.name, 'down', ordered_lines(@downs))
                    sections = @lines.inject({}) { |r, line| key = line.split(/\s+/).first; r[key] ||= []; r[key] << line; r }
                    sections.keys.sort.map do |key|
                      sections[key].map { |j| "  #{j}" } if sections[key]
                    end.compact.flatten.join("\n") + "\n\n"
                  end
                end

                attr_reader :iface

                def initialize(result, iface)
                  @result = result
                  @iface = iface
                  @header = Header.new(self)
                  @lines = Lines.new(self)
                  @skip_interfaces = false
                end

                attr_reader :result

                def name
                  @iface.name
                end

                attr_reader :header

                attr_reader :lines

                def skip_interfaces?
                  @skip_interfaces
                end

                def skip_interfaces
                  @skip_interfaces = true
                  self
                end

                def commit
                  @header.commit + @lines.commit
                end
              end

              def get(iface, name = nil)
                throw "clazz needed #{name || iface.name}" unless iface.clazz
                @entries[name || iface.name] ||= Entry.new(@result, iface)
              end

              def commit
                #      binding.pry
                out = [@entries['lo']]
                clazzes = {}
                @entries.values.each do |entry|
                  name = entry.iface.clazz # .name[entry.iface.clazz.name.rindex(':')+1..-1]
                  # puts "NAME=>#{name}:#{entry.iface.clazz.name.rindex(':')+1}:#{entry.iface.clazz.name}:#{entry.name}"
                  clazzes[name] ||= []
                  clazzes[name] << entry
                end

                %w(device wlan bond vlan bridge gre).each do |type|
                  out += (clazzes[type] || []).select { |i| !out.first || i.name != out.first.name }.sort { |a, b| a.name <=> b.name }
                end

                out.flatten.compact.inject('') { |r, entry| r += entry.commit; r }
              end
            end
          end
        end
      end
    end
  end
end
