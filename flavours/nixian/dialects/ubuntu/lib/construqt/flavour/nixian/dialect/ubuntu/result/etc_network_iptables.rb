module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result

            class EtcNetworkIptables
              def initialize
                @mangle = Section.new('mangle')
                @nat = Section.new('nat')
                @raw = Section.new('raw')
                @filter = Section.new('filter')
              end

              def empty_v4?
                @mangle.empty_v4? && @nat.empty_v4? && @raw.empty_v4? && @filter.empty_v4?
              end

              def empty_v6?
                @mangle.empty_v6? && @nat.empty_v6? && @raw.empty_v6? && @filter.empty_v6?
              end

              class Section
                class Block
                  def initialize(section)
                    @section = section
                    @rows = []
                  end

                  def empty?
                    @rows.empty?
                  end

                  class Row
                    include Util::Chainable
                    chainable_attr_value :row, nil
                    chainable_attr_value :table, nil
                    chainable_attr_value :chain, nil
                  end

                  class RowFactory
                    include Util::Chainable
                    chainable_attr_value :table, nil
                    chainable_attr_value :chain, nil
                    chainable_attr_value :rows, nil
                    def create
                      ret = Row.new.table(get_table).chain(get_chain)
                      get_rows.push(ret)
                      ret
                    end
                  end

                  def table(table, chain = nil)
                    RowFactory.new.rows(@rows).table(table).chain(chain)
                  end

                  def prerouting
                    table("", 'PREROUTING')
                  end

                  def postrouting
                    table("", 'POSTROUTING')
                  end

                  def forward
                    table("", 'FORWARD')
                  end

                  def output
                    table("", 'OUTPUT')
                  end

                  def input
                    table("", 'INPUT')
                  end

                  def commit
                    #puts @rows.inspect
                    tables = @rows.inject({}) do |r, row|
                      r[row.get_table] ||= {}
                      r[row.get_table][row.get_chain] ||= []
                      r[row.get_table][row.get_chain] << row
                      r
                    end

                    return "" if tables.empty?
                    ret = ["*#{@section.name}"]
                    ret += tables.keys.sort.map do |k|
                      v = tables[k]
                      if k.empty?
                        v.keys.map{|o| ":#{o} ACCEPT [0:0]" }
                      else
                        ":#{k} - [0:0]"
                      end
                    end

                    tables.keys.sort.each do |k,v|
                      v = tables[k]
                      v.keys.sort.each do |chain|
                        rows = v[chain]
                        table = !k.empty? ? "-A #{k}" : "-A #{chain}"
                        rows.each do |row|
                          ret << "#{table.strip} #{row.get_row.strip}"
                        end
                      end
                    end

                    ret << "COMMIT"
                    ret << ""
                    ret.join("\n")
                  end
                end

                attr_reader :jump_destinations
                def initialize(name)
                  @name = name
                  @jump_destinations = {}
                  @ipv4 = Block.new(self)
                  @ipv6 = Block.new(self)
                end

                def empty_v4?
                  @ipv4.empty?
                end

                def empty_v6?
                  @ipv6.empty?
                end

                def name
                  @name
                end

                def ipv4
                  @ipv4
                end

                def ipv6
                  @ipv6
                end

                def commitv6
                  @ipv6.commit
                end

                def commitv4
                  @ipv4.commit
                end
              end

              def mangle
                @mangle
              end

              def raw
                @raw
              end

              def nat
                @nat
              end

              def filter
                @filter
              end

              def commitv4
                mangle.commitv4+raw.commitv4+nat.commitv4+filter.commitv4
              end

              def commitv6
                mangle.commitv6+raw.commitv6+nat.commitv6+filter.commitv6
              end
            end
          end
        end
      end
    end
  end
end
