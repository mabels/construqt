module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          module Services

            FACTORY = {}

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

            def self.add_renderer(name, renderer)
              FACTORY[name] = renderer
            end

            def self.get_renderer(service)
              self.add_renderer(Construqt::Services::DhcpV4Relay, DhcpV4Relay)
              self.add_renderer(Construqt::Services::DhcpV6Relay, DhcpV6Relay)
              self.add_renderer(Construqt::Services::Radvd, Radvd)
              self.add_renderer(Construqt::Services::ConntrackD, ConntrackD)
              self.add_renderer(Construqt::Services::IpsecStartStop, Null)
              self.add_renderer(Construqt::Services::BgpStartStop, Null)
              self.add_renderer(Construqt::Flavour::Nixian::Dialect::Ubuntu::Vrrp::RouteService, RouteService)
              found = FACTORY.keys.find{ |i| service.kind_of?(i) }
              throw "service type unknown #{service.name} #{service.class.name}" unless found
              FACTORY[found].new(service)
            end
          end
        end
      end
    end
  end
end
