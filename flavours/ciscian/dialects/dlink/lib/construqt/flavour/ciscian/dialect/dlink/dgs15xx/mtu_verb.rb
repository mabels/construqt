module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Dlink
          class Dgs15xx


            class MtuVerb < PatternBasedVerb
              def self.section
                'max-rcv-frame-size'
              end

              def self.find_regex(variable)
                {
                  'frame-size' => '(.*)'
                }[variable]
              end

              def self.patterns
                ['max-rcv-frame-size {+framesize}']
              end
            end
          end
        end
      end
    end
  end
end
