module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class RejectRoutes
            def on_add(ud, taste, _, me)
              # binding.pry
              ess = @context.find_instances_from_type Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost
              ess.get("construqt-RejectRoutes.service") do |srv|
                srv.description("add reject routes to #{ud.host.name}")
                   .type("oneshot")
                   .remain_after_exit
                   .after("systemd-networkd.socket")
                   .requires("systemd-networkd.socket")
                   .exec_start("/bin/sh /etc/network/RejectRoutes-up.sh")
                   .exec_stop("/bin/sh /etc/network/RejectRoutes-down.sh")
                   .wanted_by("multi-user.target")
                   .command("restart")
              end
            end

            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::RejectRoutes, RejectRoutes)
        end
      end
    end
  end
end
