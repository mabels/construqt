module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink
          class Dgs15xx
            class WtfEnd
              def self.parse_line(line, _lines, section, _result)
                section.is_a?(Result) && ['end'].include?(line.to_s)
              end
            end
          end
        end
      end
    end
  end
end
