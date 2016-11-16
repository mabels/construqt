module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          module Services
            class Radvd
              def initialize(service)
                @service = service
              end

              def register_taste(host)
                host.result.up_downer.tastes.each do |t|
                  if t.kind_of?(Result::UpDownerDebianTaste)
                    t.dispatch[Result::UpDown::Radvd.name] = lambda {|i, u| render_debian(t, i, u) }
                  elsif t.kind_of?(Result::UpDownerFlatTaste)
                    t.dispatch[Result::UpDown::Radvd.name] = lambda {|i, u| render_flat(t, i, u) }
                  elsif t.kind_of?(Result::UpDownerSystemdTaste)
                    t.dispatch[Result::UpDown::Radvd.name] = lambda {|i, u| render_systemd(t, i, u) }
                  else
                    throw "unknown tast"
                  end
                end
              end

              def up(ifname)
                ret = "\n" + <<-OUT
#https://github.com/reubenhwk/radvd/issues/33
/sbin/sysctl -w net.ipv6.conf.#{ifname}.autoconf=0
/usr/sbin/radvd -C /etc/network/radvd.#{ifname}.conf -p /run/radvd.#{ifname}.pid
                OUT
              end
              def down(ifname)
                "kill `cat /run/radvd.#{ifname}.pid`"
              end

              def render_debian(t, iface, ud)
                writer = t.etc_network_interfaces.get(iface, ud.ifname)
                writer.lines.up(up(ud.ifname), :extra)
                writer.lines.down(down(ud.ifname), :extra)
              end

              def render_flat(t, i, ud)
                t.up(up(ud.ifname))
                t.down(down(ud.ifname))
              end

              def render_systemd(t, i, u)
              end

              def vrrp(host, ifname, iface)
                #binding.pry
                host.result.etc_network_vrrp(iface.name).add_master(up(ifname)).add_backup(down(ifname))
              end

              def interfaces(host, ifname, iface, writer, family = nil)
                #      binding.pry
                return unless iface.address && iface.address.first_ipv6
                register_taste(host.delegate)
                host.result.up_downer.add(iface, Result::UpDown::Radvd.new(ifname))
                host.result.add(self, Util.render("radvd.conf.erb"),
                  Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::RADVD),
                  "etc", "network", "radvd.#{ifname}.conf")
              end
            end
          end
        end
      end
    end
  end
end

self.add_renderer(Construqt::Services::DhcpV4Relay, DhcpV4Relay)
self.add_renderer(Construqt::Services::DhcpV6Relay, DhcpV6Relay)
self.add_renderer(Construqt::Services::Radvd, Radvd)
self.add_renderer(Construqt::Services::ConntrackD, ConntrackD)
self.add_renderer(Construqt::Services::IpsecStartStop, Null)
self.add_renderer(Construqt::Services::BgpStartStop, Null)
self.add_renderer(Construqt::Flavour::Nixian::Dialect::Ubuntu::Vrrp::RouteService, RouteService)
