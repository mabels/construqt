module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class IpTables

            def on_add(ud, taste, iface, me)
              ess = @context.find_instances_from_type Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost
              ess.get("construqt-iptables.service") do |srv|
                # binding.pry
                srv.description("loads iptables ipv4 and ipv6")
                   .type("oneshot")
                   .remain_after_exit
                   .wants("network-online.target")
                   .after("network-online.target")
                   .exec_start("/usr/sbin/iptables-restore /etc/network/iptables.cfg")
                   .exec_start("/usr/sbin/ip6tables-restore /etc/network/ip6tables.cfg")
                   .wanted_by("multi-user.target")
               end
               ess.get_drop_in("docker.service", "42-iptables-false.conf") do |dropin|
                  dropin.environment("DOCKER_OPTS=--iptables=false")
               end
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpTables, IpTables)
        end
      end
    end
  end
end
