module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink
          class Dgs15xx
            class Comment
              def self.parse_line(line, _lines, _section, _result)
                line.to_s.empty? || line.to_s.start_with?('#')
              end
            end
          end
        end
      end
    end
  end
end
