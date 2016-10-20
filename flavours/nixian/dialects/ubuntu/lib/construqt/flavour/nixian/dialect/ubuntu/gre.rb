module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Gre < OpenStruct
            def initialize(cfg)
              super(cfg)
            end

            def build_config(host, gre, node)
              gre_delegate = gre.delegate
              prepare = { }
              if gre.ipsec.transport_family.nil? || gre.ipsec.transport_family == Construqt::Addresses::IPV6
                my = gre_delegate.local.first_ipv6
                other = gre_delegate.other.interface.delegate.local.first_ipv6
                remote = gre_delegate.remote.first_ipv6
                mode_v6 = "ip6gre"
                mode_v4 = "ipip6"
                prefix = 6
              else
                remote = gre_delegate.remote.first_ipv4
                other = gre_delegate.other.interface.delegate.local.first_ipv4
                my = gre_delegate.local.first_ipv4
                mode_v6 = "sit"
                mode_v4 = "gre"
                prefix = 4
              end

              #binding.pry
              if gre_delegate.local.first_ipv6
                prepare[6] = OpenStruct.new(:gt => "gt6", :prefix=>prefix, :family => Construqt::Addresses::IPV6,
                                            :my => my, :other => other, :remote => remote, :mode => mode_v6,
                                            :mtu => gre.ipsec.mtu_v6 || 1460)
              end

              if gre_delegate.local.first_ipv4
                prepare[4] = OpenStruct.new(:gt => "gt4", :prefix=>prefix, :family => Construqt::Addresses::IPV4,
                                            :my=>my, :other => other, :remote => remote, :mode => mode_v4,
                                            :mtu => gre.ipsec.mtu_v4 || 1476)
              end

              throw "need a local address #{host.name}:#{gre_delegate.name}" if prepare.empty?

              #ip -6 tunnel add gt6naspr01 mode ip6gre local 2a04:2f80:f:f003::2 remote 2a04:2f80:f:f003::1
              #ip link set mtu 1500 dev gt6naspr01 up
              #ip addr add 2a04:2f80:f:f003::2/64 dev gt6naspr01

              #ip -4 tunnel add gt4naspr01 mode gre local 169.254.193.2 remote 169.254.193.1
              #ip link set mtu 1500 dev gt4naspr01 up
              #ip addr add 169.254.193.2/30 dev gt4naspr01

              local_ifaces = {}
              prepare.values.each do |cfg|
                local_iface = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(cfg.remote.ipaddr) }
                throw "need a interface with address #{host.name}:#{cfg.remote.ipaddr}" unless local_iface

                iname = Util.clean_if(cfg.gt, gre_delegate.name)
                local_ifaces[local_iface.name] ||= OpenStruct.new(:iface => local_iface, :inames => [])
                local_ifaces[local_iface.name].inames << iname

                writer = host.result.etc_network_interfaces.get(gre, iname)
                writer.skip_interfaces.header.interface_name(iname)
                writer.lines.up("ip -#{cfg.prefix} tunnel add #{iname} mode #{cfg.mode} local #{cfg.my.to_s} remote #{cfg.other.to_s}")
                Device.build_config(host, gre, node, iname, cfg.family, cfg.mtu)
                writer.lines.down("ip -#{cfg.prefix} tunnel del #{iname}")
              end

              local_ifaces.values.each do |val|
                if val.iface.clazz == "vrrp"
                  vrrp = host.result.etc_network_vrrp(val.iface.name)
                  val.inames.each do |iname|
                    vrrp.add_master("/bin/bash /etc/network/#{iname}-up.iface")
                  end

                  val.inames.each do |iname|
                    vrrp.add_backup("/bin/bash /etc/network/#{iname}-down.iface")
                  end
                else
                  writer_local = host.result.etc_network_interfaces.get(val.iface)
                  val.inames.each do |iname|
                    writer_local.lines.up("/bin/bash /etc/network/#{iname}-up.iface")
                    writer_local.lines.down("/bin/bash /etc/network/#{iname}-down.iface")
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
