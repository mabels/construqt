module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink
          class Dgs15xx
            class ChannelGroupVerb < PatternBasedVerb
              def self.section
                'channel-group'
              end

              def always_select_empty_pattern
                true
              end

              def self.patterns
                ['no channel-group', 'channel-group {+channel} mode active']
              end
            end
          end
        end
      end
    end
  end
end
