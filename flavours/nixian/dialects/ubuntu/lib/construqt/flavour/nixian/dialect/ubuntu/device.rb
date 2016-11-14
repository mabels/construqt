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

            def up_down_member(iface)
              []
            end
            # def up_member(iface)
            #   []
            # end
            # def down_member(iface)
            #   []
            # end

            def self.add_address(host, ifname, iface, family)
              if iface.address.nil?
                Firewall.create(host, ifname, iface, family)
                return
              end

              host.result.up_downer.add(iface, Result::UpDown::DhcpV4.new()) if iface.address.dhcpv4?
              host.result.up_downer.add(iface, Result::UpDown::DhcpV6.new()) if iface.address.dhcpv6?

              host.result.up_downer.add(iface, Result::UpDown::Loopback.new()) if iface.address.loopback?
              # lines.add(iface.flavour) if iface.flavour
              iface.address.ips.each do |ip|
                if family.nil? ||
                    (!family.nil? && family == Construqt::Addresses::IPV6 && ip.ipv6?) ||
                    (!family.nil? && family == Construqt::Addresses::IPV4 && ip.ipv4?)
                  prefix = ip.ipv6? ? "-6 " : ""
                  host.result.up_downer.add(iface, Result::UpDown::IpAddr.new(ip, ifname))
                  if ip.routing_table
                    host.result.up_downer.add(iface, Result::UpDown::IpRouteTable.new(ip, ifname))
                  end
                end
              end
              iface.address.routes.each do |route|
                if family.nil? ||
                    (!family.nil? && family == Construqt::Addresses::IPV6 && route.via.ipv6?) ||
                    (!family.nil? && family == Construqt::Addresses::IPV4 && route.via.ipv4?)
                    host.result.up_downer.add(iface, Result::UpDown::IpRoute.new(route, ifname))
                end
              end

              proxy_neigh(ifname, iface)
              Firewall.create(host, ifname, iface, family)
            end

            def self.proxy_neigh2ips(neigh)
              if neigh.nil?
                return []
              elsif neigh.respond_to?(:resolv)
                ret = neigh.resolv()
                #puts "self.proxy_neigh2ips>>>>>#{neigh} #{ret.map{|i| i.class.name}} "
                return ret
              end
              return neigh.ips
            end

            def self.proxy_neigh(ifname, iface)
              proxy_neigh2ips(iface.proxy_neigh).each do |ip|
                #puts "**********#{ip.class.name}"
                list = []
                if ip.network.to_string == ip.to_string
                  ip.each_host{|i| list << i }
                else
                  list << ip
                end
                list.each do |lip|
                  iface.host.result.up_downer.add(iface, Result::UpDown::IpProxyNeigh.new(lip, ifname))
                end
              end
            end

            def build_config(host, iface, node)
              self.class.build_config(host, iface, node)
            end

            def self.add_services(host, ifname, iface,  family)
              iface.services && iface.services.each do |service|
                Services.get_renderer(service).interfaces(host, ifname, iface,  family)
              end
            end

            def self.add_dhcp_client(host, ifname, iface,  family)
              return if iface.address.nil?
              return if !iface.address.dhcpv4?
              host.result.up_downer.add(iface, Result::UpDown::DhcpClient.new(ifname))
            end

            def self.add_dhcp_server(host, ifname, iface,  family)
              return unless iface.dhcp
              host.result.add_component(Construqt::Resources::Component::DNSMASQ)
              host.result.up_downer.add(iface, Result::UpDown::DnsMasq.new(iface, ifname))
            end

            def self.build_config(host, iface, node, ifname = nil, family = nil, mtu = nil, skip_link = nil)
              # binding.pry
              throw "need node as 3th parameter" unless node.kind_of?(Construqt::Graph::Node)
              #      binding.pry
              #          if iface.dynamic
              #            Firewall.create(host, ifname||iface.name, iface, family)
              #            return
              #          end
              #binding.pry if iface.name == "border" and iface.host.name == "ao-border-wlxc4e9841f0822"
              host.result.add_component(iface.class.const_get("COMPONENT"))


              host.result.up_downer.add(iface, Result::UpDown::Device.new(ifname))
              ifname = ifname || iface.name || writer.header.get_interface_name
              # iface.call_on_iface_up_down(writer, ifname)
              unless skip_link
                # binding.pry
                host.result.up_downer.add(iface, Result::UpDown::LinkMtuUpDown.new(mtu || iface.delegate.mtu, ifname))
              end
              iface.node.parents.each do |parent_node|
                parent = parent_node.link.ref
                parent.delegate.up_down_member(iface).each { |ud| host.result.up_downer.add(iface, ud) }
                # parent.delegate.up_member(iface).each { |line| writer.lines.up(line) }
                # parent.delegate.down_member(iface).each { |line| writer.lines.down(line) }
              end
              add_address(host, ifname, iface.delegate, family)
              #binding.pry if ifname == "v202"
              add_dhcp_client(host, ifname, iface, family)
              add_dhcp_server(host, ifname, iface,  family)
              add_services(host, ifname, iface.delegate,  family)

            end
          end
        end
      end
    end
  end
end
