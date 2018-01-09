module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class IpSecConnect
            def on_add(ud, taste, iface, me)
              ess = @context.find_instances_from_type Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost

              me.endpoint.local.interfaces.each do |iface|
                ess.get("construqt-#{iface.name}-ipsec.service") do |srv|
                  srv.description("loads ipsec for #{iface.name}")
                        .type("simple")
                        .remain_after_exit
                        .after("systemd-networkd.socket")
                        .requires("systemd-networkd.socket")
                        .requires("sys-subsystem-net-devices-#{iface.name}.device")
                        .exec_start_pre("/usr/lib/systemd/systemd-networkd-wait-online --interface=#{Util.short_ifname(iface)}")
                        .exec_start("/usr/lib/ipsec/starter; /usr/sbin/ipsec up #{me.name}")
                        .exec_stop("/usr/sbin/ipsec down #{me.name}")
                        .wanted_by("multi-user.target")
                        .command("restart")
                end
              end
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          # binding.pry
          add(Entities::IpSecConnect, IpSecConnect)
        end
      end
    end
  end
end
