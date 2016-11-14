

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            module UpDown
              class BridgeMember
                attr_reader :bname, :ifname
                def initialize(bname, ifname)
                  @bname = bname
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
