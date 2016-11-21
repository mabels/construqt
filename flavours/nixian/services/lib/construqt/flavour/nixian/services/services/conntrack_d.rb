module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          module Services


            class ConntrackD
              def initialize(service)
                @service = service
              end

              def up(ifname)
                "/usr/share/doc/conntrackd/examples/sync/primary-backup.sh primary"
              end

              def down(ifname)
                "/usr/share/doc/conntrackd/examples/sync/primary-backup.sh backup"
              end

              def vrrp(host, ifname, iface)
                #binding.pry
                host.result.etc_network_vrrp(iface.name).add_master(up(ifname)).add_backup(down(ifname))
              end

              def build_interface(host, ifname, iface, writer)
                throw "only vrrp ifaces could be used to conntrack: #{ifname}:#{iface.name}" unless iface.vrrp
                throw "conntrack needs a ipv4 address #{ifname}:#{iface.name}" unless iface.address.first_ipv4
                throw "conntrack currently a ipv4 address #{iface.host.name}:#{ifname}:#{iface.name}" unless iface.address.first_ipv4
                other_if = iface.vrrp.delegate.interfaces.find{|i| i.host != host }
                throw "conntrack currently a ipv4 address #{other_if.host.name}:#{other_if.name}" unless other_if.address.first_ipv4
                #binding.pry
                host.result.etc_conntrackd_conntrackd.add(ifname, iface.address.first_ipv4, other_if.address.first_ipv4)
              end
              Services.add_renderer(Construqt::Services::ConntrackD, ConntrackD)

            end
          end
        end
      end
    end
  end
end
