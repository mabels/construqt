module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink
          class Dgs15xx
            class ConfigureTerminal
              def self.parse_line(line, lines, section, result)
                return false unless ['configure terminal'].find { |i| line.to_s.start_with?(i) }
                while line = lines.shift
                  break if result.dialect.block_end?(line.to_s)
                  result.parse_line(line, lines, section, result)
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
