module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result

            class EtcConntrackdConntrackd
              def initialize(result)
                @result = result
                @others = []
              end

              class Other
                attr_accessor :ifname, :my_ip, :other_ip
              end

              def add(ifname, my_ip, other_ip)
                other = Other.new
                other.ifname = ifname
                other.my_ip = my_ip
                other.other_ip = other_ip
                @others << other
              end

              def commit
                return '' if @others.empty?
                Construqt::Util.render(binding, "conntrackd.erb")
              end
            end
          end
        end
      end
    end
  end
end
