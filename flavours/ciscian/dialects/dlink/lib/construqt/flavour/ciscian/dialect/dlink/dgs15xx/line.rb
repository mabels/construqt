module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink
          class Dgs15xx
            class Line
              def self.parse_line(line, lines, section, result)
                return false unless ['line '].find { |i| line.to_s.start_with?(i) }
                section.add(line, NestedSection) do |_section|
                  while line = lines.shift
                    break if result.dialect.block_end?(line.to_s)
                    result.parse_line(line, lines, _section, result)
                  end
                end

                true
              end
            end
          end
        end
      end
    end
  end
end
