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

              def interfaces(host, ifname, iface, writer)
              end
            end

            def self.get_renderer(service)
              factory = {
                Construqt::Services::DhcpV4Relay => DhcpV4Relay,
                Construqt::Services::DhcpV6Relay => DhcpV6Relay,
                Construqt::Services::Radvd => Radvd,
                Construqt::Services::ConntrackD => ConntrackD,
                Construqt::Services::IpsecStartStop => Null,
                Construqt::Services::BgpStartStop => Null,
                Construqt::Flavour::Nixian::Dialect::Ubuntu::Vrrp::RouteService => RouteService
              }
              found = factory.keys.find{ |i| service.kind_of?(i) }
              throw "service type unknown #{service.name} #{service.class.name}" unless found
              factory[found].new(service)
            end
          end
        end
      end
    end
  end
end
