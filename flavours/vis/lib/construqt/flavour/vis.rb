module Construqt
  module Flavour
    class Vis

      DIRECTORY = File.dirname(__FILE__)

      def name
        'vis'
      end

      def initialize
        @tree_view = Construqt::TreeView.new
      end

      def connect(node, out, path)
        return if node.drawed!
        #    Construqt.logger.debug("planuml.draw:#{node.reference.name} #{node.ident} ")
        node.out_links.each do |n|
          #      Construqt.logger.debug("planuml.draw:Out:#{node.reference.name} #{node.ident}:#{n.ident}")
          if TreeView.simple(node.reference.class) == "Host"
            out << { from: node.object_id, to: n.object_id }
          end
          # end

          connect(n, out, path + [n.reference.name])
        end
        node.wire_out_links.each do |n|
          key = [node.ident,n.ident].sort.join('..')
          unless @tree_view.single_wire[key]
            @tree_view.single_wire[key] = true
            out << { from: node.object_id, to: n.object_id }
          end
        end
      end

      def self.draw(node, out, path, flat, level = 0, parent = nil)
        n_kind = TreeView.simple(node.reference.class)
        if n_kind == "Host"
          # root calls but we have in_links so this is part of a
          # mother child connection
          return false if parent.nil? and !node.in_links.empty?
          # if my in_links contains my mother i'm ready to paint
          return false if !node.in_links.empty? and !node.in_links.include?(parent)
          return false if node.drawed! #ugly


          color = 192 + (level * 32)
          color = "#{"%02x"%color}#{"%02x"%color}#{"%02x"%color}"
          out << {
              id: node.object_id,
              label:"#{node.ident}(#{node.reference.flavour.name})",
              shape: 'box',
              color: {
                background:"green",
                border:'black',
                highlight:{background:"green",border:'blue'},
                hover:{background:"green",border:'red'}
              },
              cid: parent.object_id || node.object_id,
              group: (!parent.nil? && parent.ident) || node.ident
          }
        else
          return false if node.drawed! #ugly
          out << {
            id: node.object_id,
            # \n
            label: "#{node.ident}(#{TreeView.get_stereo_type(node, n_kind)})",
            title: "#{render_object_address(node.reference).join("<br/>")}",
            color: {
              background:'gray',
              border:'black',
              highlight:{background:'gray',border:'blue'},
              hover:{background:'gray',border:'red'}
            },
            cid: parent.object_id || node.object_id,
            group: (!parent.nil? && parent.ident) || node.ident
          }
        end
        #binding.pry if node.ident == 'Host_scott'

        last = nil
        !flat && n_kind != 'Device' && node.out_links.each do |n|
          #binding.pry if n.reference.name == "ad-de"
          last = TreeView.layout_helper(out, last, node,
                   draw(n, out, path + [n.reference.name], flat, level + 1, node)
                 )
        end
        true
      end

      def self.render_object_address(iface)
        tags = []
        out = []
        out << "name = \"#{iface.name}\""

        if iface.respond_to?(:shortname) && iface.name != Util.short_ifname(iface)
          out << "short_ifname = \"#{Util.short_ifname(iface)}\""
        end

        if iface.respond_to?(:mtu) && iface.mtu
          out << "mtu = \"#{iface.mtu}\""
        end
        if iface.respond_to?(:proxy_neigh) && iface.proxy_neigh
          iface.proxy_neigh.resolv().each_with_index do |i, idx|
            out << "proxy_neigh.#{idx} = #{i.to_string}"
          end
        end

        if iface.kind_of? Construqt::Tunnels::Tunnel
          out << "transport_family = \"#{iface.transport_family}\""
          out << "mtu_v4 = \"#{iface.mtu_v4}\""
          out << "mtu_v6 = \"#{iface.mtu_v6}\""
          out += self.render_services(iface)
          return out.join("\n")
        end
        #if iface.kind_of? Construqt::Ipsecs::Ipsec
        #  out << "password = #{iface.password}"
        #  out << "transport_family = #{iface.transport_family}"
        #  out << "mtu_v4 = #{iface.mtu_v4}"
        #  out << "mtu_v6 = #{iface.mtu_v6}"
        #  out << "keyexchange = #{iface.keyexchange}"
        #end

        #binding.pry if name == 'ipsec'
        address = iface.address
        if iface.kind_of? Construqt::Flavour::Delegate::IpsecVpnDelegate
          out << "auth_method = #{iface.auth_method}"
          out << "leftpsk = #{iface.leftpsk}"
          if iface.leftcert
            out << "leftcert = #{iface.leftcert.name}"
          end
          out << "ipv6_proxy = #{iface.ipv6_proxy}"
          address = iface.right_address
          ipsec_users.each do |user|
            out << "#{user.name} = #{user.psk}"
          end
        end
        if iface.respond_to?(:ssid) && iface.ssid
          out << "ssid = \"#{iface.ssid}\""
          out << "psk = \"#{iface.psk}\""
        end
        [:vlan_id,:band,:channel_width,:country,:mode,:rx_chain,:tx_chain,:hide_ssid].each do |name|
          if iface.respond_to?(name) && iface.send(name)
            out << "#{name} = \"#{iface.send(name)}\""
          end
        end

        out << "desc = \"#{iface.description}\"" if iface.description
        if address
          [address.v4s, address.v6s].each do |ips|
            next unless ips.first
            prefix = ips.first.ipv4? ? "ipv4" : "ipv6"
            ips.each_with_index do |ip, idx|
              tags += Construqt::Tags.from(ip)||[]
              out << "#{prefix}(#{idx}) = #{ip.to_string}"
              if ip.options["dhcp"]
                out << "dhcp-range(#{idx}) = [#{ip.options["dhcp"].get_start},#{ip.options["dhcp"].get_end}]"
                out << "dhcp-domain(#{idx}) = #{ip.options["dhcp"].get_domain}"
              end
            end
          end

          if address.dhcpv4?
            out << "dhcpv4 = client"
          end

          if address.dhcpv6?
            out << "dhcpv6 = client"
          end

          address.routes.each_with_index do |route, idx|
            if route.respond_to?(:dst)
              out << "route(#{idx}) = \"#{route.dst.to_string} via #{route.via.to_s}\""
            elsif route.instance_of?(Construqt::Addresses::RejectRoute)
              out << "route(#{idx}) = \"#{route.dst_addr_or_tag.to_string} to RejectRoute\""
            else
              binding.pry
            end
          end
        end

        iface.respond_to?(:delegate) &&
          iface.delegate &&
          iface.delegate.firewalls &&
          iface.delegate.firewalls.each_with_index do |fw, idx|
          out << "fw(#{idx}) = \"#{fw.name}\""
        end

        iface.respond_to?(:tags) &&
          iface.tags &&
          (iface.tags+tags).sort.uniq.each_with_index do |tag, idx|
          out << "tag(#{idx}) = \"#{tag}\""
        end

        out += self.render_services(iface)

        out
      end

      def self.render_services(iface)
        out = []
        iface.services && iface.services.map{|i| i}.each_with_index do |service, idx|
          out << "service(#{idx}) = \"#{service.class.name}\""
          if service.respond_to?(:render_vis)
            out << service.render_vis
          end
        end
        out
      end

      def call(type, host_or_region, *args)
        @tree_view.add_node_factory(type, host_or_region, *args)
        # return
        factory = {
          "completed" => lambda do |type, *args|
            @tree_view.build_tree
            nodes = []
            last = nil
            @tree_view.tree.values.each do |node|
              #           next unless node.in_links.empty?
              last = TreeView.layout_helper(nodes, last, node,
                         Vis.draw(node, nodes, [node.reference.name],
                         ['Vrrp', 'Ipsec', 'Bgp'].include?(TreeView.simple(node.reference.class))))
            end

            @tree_view.tree.values.each { |n| n.drawed = false }
            edges = []
            @tree_view.tree.values.each do |node|
              #           next unless node.in_links.empty?
              connect(node, edges, [node.reference.name])
            end

            dst_path = Construqt::Util.dst_path(host_or_region)
            File.open(File.join(dst_path, "world.vis.html"), 'w') do |file|
              file.write(Construqt::Util.render(binding, "vis.html.erb"))
            end
          end

        }
        # Construqt.logger.debug "Planuml:#{type}"
        action = factory[type]
        if action
          action.call(type, *args)
        end
      end
    end
  end
end
