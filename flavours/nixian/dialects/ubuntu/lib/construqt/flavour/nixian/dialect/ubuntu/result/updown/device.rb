

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            module UpDown
              class Device
                attr_reader :ifname
                def initialize(ifname)
                  @ifname = ifname
                end
              end
            end
          end
        end
      end
    end
  end
end
