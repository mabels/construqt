module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Bridge
            def on_add(ud, taste, iface, me)
              # binding.pry if iface.host.name == "thieso"
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface, me.ifname)
              if iface.interfaces.empty?
                writer.lines.add("bridge_ports none", 0)
              else
                brifs = iface.interfaces.map {|brif| brif.name}.join(" ")
                writer.lines.add("bridge_ports #{brifs}", 0)
              end
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Bridge, Bridge)
        end
      end
    end
  end
end
