module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class DhcpClient
            def activate(ctx)
              @context = ctx
              self
            end

            def on_add(ud, taste, iface, me)
              return if iface.address.nil?
              return if !iface.address.dhcpv4?
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface, me.ifname)
              writer.lines.up(up(me.ifname), :extra)
              writer.lines.down(down(me.ifname), :extra)
            end
          end

          add(Entities::DhcpClient, DhcpClient)
        end
      end
    end
  end
end
