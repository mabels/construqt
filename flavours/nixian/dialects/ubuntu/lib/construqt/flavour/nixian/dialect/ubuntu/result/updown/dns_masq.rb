

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            module UpDown
              class DnsMasq
                attr_reader :iface, :ifname
                def initialize(iface, ifname)
                  @iface = iface
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
