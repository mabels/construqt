

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            module UpDown
              class Bgp
                attr_reader :ip, :ifname
                def initialize(ip, ifname)
                  @ip = ip
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
