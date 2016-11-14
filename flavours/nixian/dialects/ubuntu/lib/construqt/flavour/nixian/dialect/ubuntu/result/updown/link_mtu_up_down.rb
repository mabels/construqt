

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            module UpDown
              class LinkMtuUpDown
                attr_reader :mtu, :ifname
                def initialize(mtu, ifname)
                  @mtu = mtu
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
