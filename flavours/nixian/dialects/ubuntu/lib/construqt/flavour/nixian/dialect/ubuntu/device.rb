require_relative 'base_device'
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Device #< OpenStruct
            include BaseDevice
            include Construqt::Cables::Plugin::Single
            def initialize(cfg)
              base_device(cfg)
            end

            def belongs_to
              [self.host]
            end

            #def up_down_member(iface)
            #  []
            #end
            # def up_member(iface)
            #   []
            # end
            # def down_member(iface)
            #   []
            # end

            def self.add_address(host, ifname, iface, family, result, up_downer)
              if iface.address.nil?
                Firewall.create(host, ifname, iface, family)
                return
              end

              up_downer.add(iface, Tastes::Entities::DhcpV4.new()) if iface.address.dhcpv4?
              up_downer.add(iface, Tastes::Entities::DhcpV6.new()) if iface.address.dhcpv6?

              up_downer.add(iface, Tastes::Entities::Loopback.new()) if iface.address.loopback?
              lines.add(iface.flavour) if iface.flavour
              iface.address.ips.each do |ip|
                if family.nil? ||
                    (!family.nil? && family == Construqt::Addresses::IPV6 && ip.ipv6?) ||
                    (!family.nil? && family == Construqt::Addresses::IPV4 && ip.ipv4?)
                  prefix = ip.ipv6? ? "-6 " : ""
                  up_downer.add(iface, Tastes::Entities::IpAddr.new(ip, ifname))
                  if ip.routing_table
                    up_downer.add(iface, Tastes::Entities::IpRouteTable.new(ip, ifname))
                  end
                end
              end
              iface.address.routes.each do |route|
                if family.nil? ||
                    (!family.nil? && family == Construqt::Addresses::IPV6 && route.via.ipv6?) ||
                    (!family.nil? && family == Construqt::Addresses::IPV4 && route.via.ipv4?)
                    up_downer.add(iface, Tastes::Entities::IpRoute.new(route, ifname))
                end
              end
              # up_downer.add(@host, Tastes::Entities::IpProxyNeigh.new(iface))
              # iptables = host.result_types.find_instances_from_type(Construqt::Flavour::Nixian::Services::IpTables::OncePerHost)
              # iptables.create(host, ifname, iface, family)
            end

            def build_config(host, iface, node)
              self.class.build_config(host, iface, node)
            end


            def self.build_config(host, iface, node, ifname = nil, family = nil, mtu = nil, skip_link = nil)
              # binding.pry
              throw "need node as 3th parameter" unless node.kind_of?(Construqt::Graph::Node)
              result = host.result_types.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              #      binding.pry
              #          if iface.dynamic
              #            Firewall.create(host, ifname||iface.name, iface, family)
              #            return
              #          end
              #binding.pry if iface.name == "border" and iface.host.name == "ao-border-wlxc4e9841f0822"
              #result.add_component(iface.class.const_get("COMPONENT"))

              up_downer = host.result_types.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
              up_downer.add(iface, Tastes::Entities::Device.new(ifname))
              ifname = ifname || iface.name || writer.header.get_interface_name
              # iface.call_on_iface_up_down(writer, ifname)
              unless skip_link
                # binding.pry
                up_downer.add(iface, Tastes::Entities::LinkMtuUpDown.new(mtu || iface.delegate.mtu, ifname))
              end
              #iface.node.parents.each do |parent_node|
              #  parent = parent_node.link.ref
              #  #parent.delegate.up_down_member(iface).each { |ud| up_downer.add(iface, ud) }
              #  # parent.delegate.up_member(iface).each { |line| writer.lines.up(line) }
              #  # parent.delegate.down_member(iface).each { |line| writer.lines.down(line) }
              #end
              add_address(host, ifname, iface.delegate, family, result, up_downer)
              # binding.pry
              # #binding.pry if ifname == "v202"
              # iface.services.each do |service|
              #   # binding.pry
              #   host.flavour.services.find(service).build_interface(host, ifname, iface,  family)
              # end

            end
          end
        end
      end
    end
  end
end
