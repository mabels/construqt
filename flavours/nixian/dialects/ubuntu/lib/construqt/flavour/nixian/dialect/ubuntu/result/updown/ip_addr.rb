

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            module UpDown
              class IpAddr
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
