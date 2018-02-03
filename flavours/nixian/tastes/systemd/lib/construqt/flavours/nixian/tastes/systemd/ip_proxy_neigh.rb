module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class IpProxyNeigh
            def on_add(ud, taste, _, me)
              ess = @context.find_instances_from_type Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost
              ess.get("construqt-#{me.iface.name}-IpProxyNeigh.service") do |srv|
                # binding.pry
                srv.description("proxy neigh entries for #{me.iface.name}")
                   .type("oneshot")
                   .remain_after_exit
                   .after("systemd-networkd.socket")
                   .after("network-online.target")
                   .requires("systemd-networkd.socket")
                   .requires("network-online.target")
                   .requires("sys-subsystem-net-devices-#{me.iface.name}.device")
                   .exec_start_pre("/bin/sh -c 'PATH=/lib/systemd:/usr/lib/systemd:$PATH env systemd-networkd-wait-online --interface=#{me.iface.name}'")
                   .exec_start("/bin/sh /etc/network/#{me.iface.name}-IpProxyNeigh-up.sh")
                   .exec_stop("/bin/sh /etc/network/#{me.iface.name}-IpProxyNeigh-down.sh")
                   .wanted_by("multi-user.target")
                   .command("restart")
              end
            end

            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpProxyNeigh, IpProxyNeigh)
        end
      end
    end
  end
end
