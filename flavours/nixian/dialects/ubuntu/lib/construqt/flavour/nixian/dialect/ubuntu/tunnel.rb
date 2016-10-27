module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Tunnel < OpenStruct
            include Construqt::Cables::Plugin::Single
            def initialize(cfg)
              super(cfg)
            end

            def build_config(host, iface, node)
              # binding.pry

              #ip -6 tunnel add gt6naspr01 mode ip6gre local 2a04:2f80:f:f003::2 remote 2a04:2f80:f:f003::1
              #ip link set mtu 1500 dev gt6naspr01 up
              #ip addr add 2a04:2f80:f:f003::2/64 dev gt6naspr01

              #ip -4 tunnel add gt4naspr01 mode gre local 169.254.193.2 remote 169.254.193.1
              #ip link set mtu 1500 dev gt4naspr01 up
              #ip addr add 169.254.193.2/30 dev gt4naspr01
              # binding.pry if host.name == "scable-1"

              cfg = iface.delegate.tunnel
              local_iface = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(cfg.remote.ipaddr) }
              throw "need a interface with address #{host.name}:#{cfg.remote.ipaddr}" unless local_iface

              # iname = Util.clean_if(cfg.gt, gre_delegate.name)
              # local_ifaces[local_iface.name] ||= OpenStruct.new(:iface => local_iface, :inames => [])
              # local_ifaces[local_iface.name].inames << iname

              writer = host.result.etc_network_interfaces.get(iface)
              #writer.skip_interfaces.header.interface_name(iname)
              writer.lines.up("ip -#{cfg.prefix} tunnel add #{iface.name} mode #{cfg.mode} local #{cfg.my.to_s} remote #{cfg.other.to_s}")
              #Device.build_config(host, gre, node, iname, cfg.family, cfg.mtu)
              writer.lines.down("ip -#{cfg.prefix} tunnel del #{iface.name}")

              Device.build_config(host, iface, node)

              # local_ifaces.values.each do |val|
              #   if val.iface.clazz == "vrrp"
              #     vrrp = host.result.etc_network_vrrp(val.iface.name)
              #     val.inames.each do |iname|
              #       vrrp.add_master("/bin/bash /etc/network/#{iname}-up.iface")
              #     end
              #
              #     val.inames.each do |iname|
              #       vrrp.add_backup("/bin/bash /etc/network/#{iname}-down.iface")
              #     end
              #   else
              #     writer_local = host.result.etc_network_interfaces.get(val.iface)
              #     val.inames.each do |iname|
              #       writer_local.lines.up("/bin/bash /etc/network/#{iname}-up.iface")
              #       writer_local.lines.down("/bin/bash /etc/network/#{iname}-down.iface")
              #     end
              #   end
              # end
            end
          end
        end
      end
    end
  end
end
