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
                srv.description("dnsmasq for #{me.iface.name} with range #{me.cfg.get_start}-#{me.cfg.get_end}")
                   .type("simple")
                   .after("systemd-networkd.socket")
                   .requires("systemd-networkd.socket")
                   .exec_start_pre("/usr/lib/systemd/systemd-networkd-wait-online --interface=#{me.iface.name}")
                   .exec_start("/usr/bin/env #{cmd.join(' ')}")
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
