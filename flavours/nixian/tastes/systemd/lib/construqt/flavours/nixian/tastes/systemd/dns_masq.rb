module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class DnsMasq

            def on_add(ud, taste, _, me)
              cmd = me.start_cmd.clone
              cmd << '--keep-in-foreground'
              ess = @context.find_instances_from_type Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost
              ess.get("construqt-#{me.iface.name}-dnsmasq.service") do |srv|
                # binding.pry
                #.exec_start_pre("/usr/lib/systemd/systemd-networkd-wait-online --interface=#{me.iface.name}")
                srv.description("dnsmasq for #{me.iface.name} with range #{me.cfg.get_start}-#{me.cfg.get_end}")
                   .type("simple")
                   .after("systemd-networkd.socket")
                   .after("network-online.target")
                   .requires('systemd-networkd.socket')
                   .requires("network-online.target")
                   .exec_start_pre("/bin/sh -c 'PATH=/lib/systemd:/usr/lib/systemd:$PATH env systemd-networkd-wait-online --interface=#{me.iface.name}'")
                   .exec_start("/usr/bin/env #{cmd.join(' ')}")
                   .restart("on-failure")
                   .restart_sec(5)
                   .wanted_by("multi-user.target")
                   .system_disable_service('dnsmasq.service')
                   # .exec_stop("/bin/kill -HUP $MAINPID")
              end
            end

            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::DnsMasq, DnsMasq)
        end
      end
    end
  end
end
