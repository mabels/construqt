require_relative 'base_device'
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Tunnel
            include BaseDevice
            include Construqt::Cables::Plugin::Single
            attr_reader :interfaces, :tunnel
            def initialize(cfg)
              base_device(cfg)
              @interfaces = cfg['interfaces']
              @tunnel = cfg['tunnel']
            end

            def kind
              if self.tunnel.mode == "ipip6"
                kind = "ip6tnl"
              else
                kind = self.tunnel.mode
              end
            end
            def kind
              self.tunnel.mode
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

              # iname = Util.clean_if(cfg.gt, gre_delegate.name)
              # local_ifaces[local_iface.name] ||= OpenStruct.new(:iface => local_iface, :inames => [])
              # local_ifaces[local_iface.name].inames << iname
              # binding.pry if iface.host.name == "fanout-de"

              # writer = host.result.etc_network_interfaces.get(iface)
              #writer.skip_interfaces.header.interface_name(iname)
              local = cfg.my.first_by_family(cfg.transport_family).to_s
              remote = cfg.other.first_by_family(cfg.transport_family).to_s
              throw "there must be a local or remote address" if local.nil? or remote.nil?
              host.result.up_downer.add(iface, Tastes::Entities::Tunnel.new(cfg, local, remote))

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
