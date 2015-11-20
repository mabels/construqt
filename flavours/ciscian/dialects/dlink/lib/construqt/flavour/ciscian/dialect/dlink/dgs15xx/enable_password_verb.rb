module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink
          class Dgs15xx


            class EnablePasswordVerb < SingleValueVerb
              def self.section
                'enable password level'
              end

              def self.patterns
                ['no channel-group', 'enable password level {+admin} {+level} {+pw_hash}']
              end
            end
          end
        end
      end
    end
  end
end
