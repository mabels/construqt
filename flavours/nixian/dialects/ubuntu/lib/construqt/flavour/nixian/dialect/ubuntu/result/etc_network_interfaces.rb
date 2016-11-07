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

              class Line
                attr_reader :block, :order, :extra
                def initialize(block, order, extra)
                  @block = block
                  @order = order
                  @extra = extra
                end
                def lines
                  @block.each_line.map(&:strip).select { |i| !i.empty? }
                end
              end

              class Lines
                def initialize(entry)
                  @entry = entry
                  @lines = []
                  @ups = []
                  @downs = []
                end

                def up(block, order = 0, extra = false)
                  if order == :extra
                    order = 0
                    extra = true
                  end
                  binding.pry unless order.kind_of?(Fixnum)
                  @ups.push Line.new(block, order, extra)
                end

                def down(block, order = 0, extra = false)
                  if order == :extra
                    order = 0
                    extra = true
                  end
                  binding.pry unless order.kind_of?(Fixnum)
                  @downs.unshift Line.new(block, order, extra)
                end

                def add(block, extra)
                  @lines += Line.new(block, 0, extra).lines
                end

                def write_s(component, direction, blocks)
                  @entry.result.add(self.class, Construqt::Util.render(binding, "interfaces_sh_envelop.erb"),
                    Construqt::Resources::Rights.root_0755(component),
                    'etc', 'network', "#{@entry.header.get_interface_name}-#{direction}.sh")
                  sh_script = File.join('/etc', 'network', "#{@entry.header.get_interface_name}-#{direction}.sh")
                  @entry.result.add(self.class, Construqt::Util.render(binding, "interfaces_upscript_envelop.erb"),
                    Construqt::Resources::Rights.root_0755(component),
                    'etc', 'network', "#{@entry.header.get_interface_name}-#{direction}.iface")
                end

                def self.ordered_lines(lines)
                  # binding.pry
                  result = lines.inject({}) { |r, l| r[l.order] ||= []; r[l.order] << l.lines; r }
                  result.keys.sort.map { |key| result[key] }.flatten
                end

                def commit
                  write_s(@entry.iface.class.name, 'up', Lines.ordered_lines(@ups))
                  write_s(@entry.iface.class.name, 'down', Lines.ordered_lines(@downs))
                  sections = @lines.inject({}) do |r, line|
                    key = line.split(/\s+/).first; r[key] ||= []
                    r[key] << line
                    r
                  end
                  ret = sections.keys.sort.map do |key|
                    sections[key].map { |j| "  #{j}" } if sections[key]
                  end.compact.flatten.join("\n") + "\n\n"
                end
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

                  def auto
                    @auto = true
                  end

                  def post_up(block, order = 0)
                    @post_ups.push Line.new(block, order, false)
                  end

                  def pre_down(block, order = 0)
                    @pre_downs.unshift Line.new(block, order, false)
                  end

                  def initialize(entry)
                    @entry = entry
                    @auto = false
                    @mode = MODE_MANUAL
                    @protocol = PROTO_INET4
                    @interface_name = nil
                    @post_ups = []
                    @pre_downs = []
                  end

                  def interface_name(name)
                    @interface_name = name
                  end

                  def get_interface_name
                    @interface_name || @entry.iface.name
                  end

                  def commit
                    return '' if @entry.skip_interfaces?
                    Construqt::Util.render(binding, "interfaces_iface.erb")
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
                ret = @entries[name || iface.name]
                unless ret
                  entry = Entry.new(@result, iface)
                  ret = @entries[name || iface.name] = entry
                end
                ret
              end

              def commit
                out = []
                if_strings = @result.host.delegate.interface_graph.flat
                if_strings.each do |if_string|
                  if_string.each_with_index do |inode, idx|
                    binding.pry unless @entries[inode.ref.name]
                    out << @entries[inode.ref.name]
                    if idx == 0
                      @entries[inode.ref.name].header.auto
                    end
                    if idx + 1 == if_string.length
                      @entries[inode.ref.name].header.post_up "/sbin/iptables-restore /etc/network/iptables.cfg"
                      @entries[inode.ref.name].header.post_up "/sbin/ip6tables-restore /etc/network/ip6tables.cfg"
                    else
                      @entries[inode.ref.name].header.post_up "/sbin/ifup #{if_string[idx+1].ref.name}"
                      @entries[inode.ref.name].header.pre_down "/sbin/ifdown #{if_string[idx+1].ref.name}"
                    end
                  end
                end
                # out = [@entries['lo']]
                #
                # clazzes = {}
                # @entries.values.each do |entry|
                #   name = entry.iface.clazz # .name[entry.iface.clazz.name.rindex(':')+1..-1]
                #   # puts "NAME=>#{name}:#{entry.iface.clazz.name.rindex(':')+1}:#{entry.iface.clazz.name}:#{entry.name}"
                #   clazzes[name] ||= []
                #   clazzes[name] << entry
                # end
                #
                # %w(device wlan bond vlan bridge gre).each do |type|
                #   out += (clazzes[type] || []).select { |i| !out.first || i.name != out.first.name }.sort { |a, b| a.name <=> b.name }
                # end

                # binding.pry if @resut.host.name == "scable-1"
                  # binding.pry unless @entries[inode.ref.name]
                out.flatten.compact.inject('') { |r, entry| r += entry.commit; r }
              end
            end
          end
        end
      end
    end
  end
end
