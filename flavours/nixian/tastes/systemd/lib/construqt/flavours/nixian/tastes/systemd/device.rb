module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class Device

            def initialize
              @interfaces = {}
            end

            def activate(ctx)
              @context = ctx
              self
            end

            # def commit
            #   @interfaces.values.each do |sysdev|
            #     sysdev.commit(result)
            #   end
            #   # binding.pry
            #   #eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
            #   #writer = eni.get(iface, me.ifname)
            #   #writer.header.protocol(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost::Entry::Header::PROTO_INET4)
            #   #writer.lines.add(iface.delegate.flavour) if iface.delegate.flavour
            # end

            def on_add(ud, taste, iface, me)
              # binding.pry
              etc_systemd_netlink = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcSystemdNetlink::OncePerHost)
              etc_systemd_netlink.add(iface)
              etc_systemd_netdev = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcSystemdNetdev::OncePerHost)
              etc_systemd_netdev.add(iface)
              etc_systemd_network = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcSystemdNetwork::OncePerHost)
              etc_systemd_network.add(iface)
            end
          end
          add(Entities::Device, Device)
        end
      end
    end
  end
end
