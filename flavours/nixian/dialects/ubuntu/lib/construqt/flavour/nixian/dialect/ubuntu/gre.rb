require_relative 'base_device'
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Gre
            include BaseDevice
            include Construqt::Cables::Plugin::Single
            attr_reader :ipsec, :remote, :local, :other
            def initialize(cfg)
              base_device(cfg)
              @ipsec = cfg['ipsec']
              @remote = cfg['remote']
              @local = cfg['local']
              @other = cfg['other']
            end

            def get_prepare(gre_delegate)
              prepare = { }
              if self.ipsec.transport_family.nil? || self.ipsec.transport_family == Construqt::Addresses::IPV6
                remote = self.remote.first_ipv6
                mode_v6 = "ip6gre"
                mode_v4 = "ipip6"
                transport_family = Construqt::Addresses::IPV6
                prefix = 6
              else
                remote = self.remote.first_ipv4
                mode_v6 = "sit"
                mode_v4 = "gre"
                transport_family = Construqt::Addresses::IPV4
                prefix = 4
              end

              #binding.pry
              if self.local.first_ipv6
                prepare[6] = OpenStruct.new(:gt => "gt6", :prefix=>prefix, :family => Construqt::Addresses::IPV6,
                                            :my => self.local,
                                            :transport_family => transport_family,
                                            :other => self.other.interface.delegate.local,
                                            :remote => remote, :mode => mode_v6,
                                            :mtu => gre_delegate.ipsec.mtu_v6 || 1460)
              end
              if self.local.first_ipv4
                prepare[4] = OpenStruct.new(:gt => "gt4", :prefix=>prefix, :family => Construqt::Addresses::IPV4,
                                            :my=>self.local,
                                            :transport_family => transport_family,
                                            :other => self.other.interface.delegate.local,
                                            :remote => remote, :mode => mode_v4,
                                            :mtu => gre_delegate.ipsec.mtu_v4 || 1476)
              end
              throw "need a local address #{host.name}:#{gre_delegate.name}" if prepare.empty?
              prepare
            end

            def create_interfaces(host, name, node)
              gre_delegate = self.delegate
              prepare = get_prepare(gre_delegate)
              #local_ifaces = {}

              prepare.values.map do |cfg|
                iname = Util.clean_if(cfg.gt, gre_delegate.name)
                local_iface = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(cfg.remote.ipaddr) }
                throw "need a interface with address #{host.name}:#{cfg.remote.ipaddr}" unless local_iface
                # binding.pry if iname == "gt4rtwlmgt"
                #binding.pry
                addrs = host.region.network.addresses.create
                cfg.my.by_family(cfg.family).map do |adr|
                  addrs.add_ip(adr.to_string)
                end
                cfg.my.routes.each do |rt|
                  if cfg.family == Construqt::Addresses::IPV4 && rt.dst.ipv4? ||
                     cfg.family == Construqt::Addresses::IPV6 && rt.dst.ipv6?
                    addrs.add_route(rt.dst.to_string, rt.via.to_s, rt.options)
                  end
                end
                gt = host.region.interfaces.add_device(host, iname,
                  "address" => addrs,
                  "interfaces" => [local_iface],
                  "firewalls" => gre_delegate.firewalls.map{|i| i.name},
                  "tunnel" => cfg,
                  "clazz" => "tunnel")
                # binding.pry if host.name == "iscaac"
                # local_iface.add_child(gt)
                # gt.add_child(local_iface)
                gre_delegate.add_child(gt)
                gt.add_child(gre_delegate)
                # gt.add_child(gre_delegate)
                # binding.pry

                # local_ifaces[local_iface.name] ||= OpenStruct.new(:iface => local_iface, :inames => [])
                # local_ifaces[local_iface.name].inames << iname

                #writer = host.result.etc_network_interfaces.get(gre, iname)
                #writer.skip_interfaces.header.interface_name(iname)
                #writer.lines.up("ip -#{cfg.prefix} tunnel add #{iname} mode #{cfg.mode} local #{cfg.my.to_s} remote #{cfg.other.to_s}")
                #Device.build_config(host, gre, node, iname, cfg.family, cfg.mtu)
                #writer.lines.down("ip -#{cfg.prefix} tunnel del #{iname}")
              end

              # binding.pry if host.name == "rt-ab-de"
            end

            def build_config(host, gre, node)
              gre_delegate = gre.delegate
              # prepare = get_prepare(gre_delegate)

              # binding.pry if gre.name == "fanout-de"

              # iname = local_if.name
              # #if local_if.clazz == "gre"
              # #  iname = Util.clean_if(gt, iname)
              # #end
              # writer = host.result.etc_network_interfaces.get(iface, "fanout-de")
              # binding.pry
              up_downer = host.result_types.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
              up_downer.add(gre, Tastes::Entities::IpSecConnect.new("#{self.host.name}-#{self.other.host.name}"))

              #writer.skip_interfaces.header.interface_name(gre.name)

            end
          end
        end
      end
    end
  end
end
