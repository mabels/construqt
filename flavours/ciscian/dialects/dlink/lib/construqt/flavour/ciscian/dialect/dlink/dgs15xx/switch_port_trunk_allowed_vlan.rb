module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink
          class Dgs15xx

            class SwitchPortTrunkAllowedVlan < PatternBasedVerb
              def self.section
                'switchport trunk allowed vlan'
              end

              def self.patterns
                ['no switchport trunk allowed vlan', 'switchport trunk allowed vlan {=vlans}']
              end
            end
          end
        end
      end
    end
  end
end
