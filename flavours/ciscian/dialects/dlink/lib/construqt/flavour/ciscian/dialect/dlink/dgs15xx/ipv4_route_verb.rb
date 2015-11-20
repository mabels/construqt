module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink
          class Dgs15xx
            class Ipv4RouteVerb < PatternBasedVerb
              def self.section
                'ip route'
              end

              def group?
                false
              end

              def self.find_regex(variable)
                {
                  'routedefs' => '(\\S+\\s+\\S+\\s+\\S+)'
                }[variable]
              end

              def self.patterns
                ['no ip route {-routedefs}', 'ip route {+routedefs}']
              end
            end
          end
        end
      end
    end
  end
end
