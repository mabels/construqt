module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class DnsMasq

            def on_add(ud, taste, _, me)
              cmd = me.start_cmd
              ess = @context.find_instances_from_type Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost
              ess.get("construqt-#{me.iface.name}-dnsmasq.service") do |srv|
                # binding.pry
                #.exec_start_pre("/usr/lib/systemd/systemd-networkd-wait-online --interface=#{me.iface.name}")
                srv.description("dnsmasq for #{me.iface.name} with range #{me.cfg.get_start}-#{me.cfg.get_end}")
                   .type("simple")
                   .after("network.target")
                   .exec_start("/usr/bin/env #{cmd.join(' ')}")
                   .exec_stop("/bin/kill -HUP $MAINPID")
                   .restart("on-failure")
                   .restart_sec(5)
                   .wanted_by("multi-user.target")
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
