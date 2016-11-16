module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          module Services
            class Null
              def initialize(service)

              end

              def up(ifname)
              end

              def down(ifname)
              end

              def vrrp(host, ifname, iface)
              end

              def interfaces(host, ifname, iface, writer, family = nil)
              end
            end
          end
        end
      end
    end
  end
end
