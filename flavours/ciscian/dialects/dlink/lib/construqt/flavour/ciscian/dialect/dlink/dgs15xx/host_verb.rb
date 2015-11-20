module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink
          class Dgs15xx


            class HostNameVerb < PatternBasedVerb
              def self.section
                'snmp-server name'
              end

              def self.find_regex(variable)
                {
                  'name' => '(.*)'
                }[variable]
              end

              def self.patterns
                ['snmp-server name {+name}']
              end
            end
          end
        end
      end
    end
  end
end
