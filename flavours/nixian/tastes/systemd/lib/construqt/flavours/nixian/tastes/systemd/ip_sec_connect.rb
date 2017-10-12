module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class IpSecConnect
            def on_add(ud, taste, iface, me)
              ess = @context.find_instances_from_type Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost
              ess.get("construqt-ipsec.service") do |srv|
                #binding.pry
                srv.description("loads ipsec")
                   .type("oneshot")
                   .remain_after_exit
                   .wants("network-online.target")
                   .after("network-online.target")
                   .wanted_by("multi-user.target")
                   .command("restart")
                  srv.exec_start("/usr/lib/ipsec/starter --nofork")
                  srv.exec_start("/usr/sbin/ipsec stop")
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
