module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink
          class Dgs15xx
            class IpHttpServerVerb < SingleValueVerb
              def self.parse_line(line, _lines, section, _result)
                regexp = /^\s*((no|) ip http server)$/
                if line.to_s.strip =~ regexp
                  section.add(line.to_s, Ciscian::SingleValueVerb)
                  return true
                end
              end
            end
          end
        end
      end
    end
  end
end
