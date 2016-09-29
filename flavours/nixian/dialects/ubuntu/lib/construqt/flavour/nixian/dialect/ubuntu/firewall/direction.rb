module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Firewall
            class Direction
              attr_reader :to_from, :family, :protocol  #, :begin, :end, :middle
              def initialize(to_from, family)
                @to_from = to_from
                @family = family
                @begin_middle_end = BeginEndMiddle.new
                @on_jump_tables = []
              end

              def self.prepare_ports(ports)
                ports.map{|i| (i.instance_of?(Array) && i.join(":")) || i }
                  .join(",")
              end

              def push_begin(str)
                @begin_middle_end.push_begin(str)
                self
              end

              def push_middle(str)
                @begin_middle_end.push_middle(str)
                self
              end

              def push_end(str)
                @begin_middle_end.push_end(str)
                self
              end

              def interface_direction(dir)
                @interface_direction = dir
                self
              end

              def get_interface_direction
                @interface_direction
              end

              def set_writer(writer)
                @to_from.set_writer(writer)
                self
              end

              def ifname
                "#{@interface_direction} #{to_from.ifname}"
              end

              def set_action(action)
                @action = action
                self
              end

              def action
                @action || to_from.rule.get_action
              end

              def row(line, table_name = nil)
                factory = to_from.writer.create
                factory.table(table_name) unless table_name.nil?
                factory.row("#{line}")
              end

              def protocols
                pl = []
                @to_from.rule.get_protocols(@family).each do |proto|
                  pl << "-p #{proto}#{Util.space_before(@to_from.rule.get_proto_flags[proto])}"
                end

                pl << '' if pl.empty?
                pl
              end

              def link_local?
                @to_from.rule.link_local?
              end

              def for_family?(family)
                (family == Construqt::Addresses::IPV4 && @to_from.rule.ipv4?) || (family == Construqt::Addresses::IPV6 && @to_from.rule.ipv6?)
              end

              def get_on_jump_table
                @on_jump_tables
              end

              def on_jump_table(&block)
                @on_jump_tables << block
              end

              def create_begin_middle_end(protocol)
                @protocol = @begin_middle_end.clone
                @protocol.push_begin(protocol)
                @protocol
              end
            end
          end
        end
      end
    end
  end
end
