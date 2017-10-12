module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class IpSecConnect
            def on_add(ud, taste, iface, me)
              binding.pry
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface)
              writer.lines.up("/usr/sbin/ipsec start", :extra) # no down this is also global
              writer.lines.up("/usr/sbin/ipsec up #{me.name} &", 1000, :extra)
              writer.lines.down("/usr/sbin/ipsec down #{me.name} &", -1000, :extra)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpSecConnect, IpSecConnect)
        end
      end
    end
  end
end
