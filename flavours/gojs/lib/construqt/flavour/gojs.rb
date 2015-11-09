require 'json'

module Construqt
  module Flavour
    module GoJs

      def self.name
        'gojs'
      end

      Flavour.add_aspect(self)

      def self.simple(clazz)
        #     clazz
        clazz.name[clazz.name.rindex(':')+1..-1].gsub(/Delegate$/,'')
      end

      TREE = {}
      SINGLE_WIRE = {}

      def self.connect(node, out, path)
        return if node.drawed!
        return
        #    Construqt.logger.debug("gojs.draw:#{node.reference.name} #{node.ident} ")
        node.out_links.each do |n|
          #      Construqt.logger.debug("gojs.draw:Out:#{node.reference.name} #{node.ident}:#{n.ident}")
          unless simple(node.reference.class) == "Host"
            out << "#{node.ident} .. #{n.ident}"
          end

          connect(n, out, path + [n.reference.name])
        end
        node.wire_out_links.each do |n|
          key = [node.ident,n.ident].sort.join('..')
          unless SINGLE_WIRE[key]
            SINGLE_WIRE[key] = true
            out << "#{node.ident} .. #{n.ident}"
          end
        end
      end

      def self.ident(path, content)
        ident = (0...path.length-1).to_a.map{ " " }.join('')
        content.lines.map{|i| ident+i }.join('')
      end

      def self.get_stereo_type(node, name)
        if node.reference.respond_to?(:stereo_type)
          node.reference.stereo_type || name
        else
          name
        end
      end

      def self.draw(node, out, path, flat, level = 0, parent = nil)
        n_kind = simple(node.reference.class)
        if n_kind == "Host"
          out << {
            "key" => node.ident,
            "name" => node.reference.name,
            "ins" => [],
            "out" => [],
          }
#          # root calls but we have in_links so this is part of a
#          # mother child connection
#          return false if parent.nil? and !node.in_links.empty?
#          # if my in_links contains my mother i'm ready to paint
#          return false if !node.in_links.empty? and !node.in_links.include?(parent)
#          return false if node.drawed! #ugly
#          color = 192 + (level * 32)
#          color = "#{"%02x"%color}#{"%02x"%color}#{"%02x"%color}"
#          out << ident(path, "package \"#{node.ident}(#{node.reference.flavour.name})\" <<Node>> ##{color} {")
#        else
#          return false if node.drawed! #ugly
#          out << ident(path, <<UML)
#object #{node.ident} <<#{get_stereo_type(node, n_kind)}>> {
#          #{render_object_address(node.reference)}
#}
#UML
        end
        #binding.pry if node.ident == 'Host_scott'

        last = nil
        !flat && n_kind != 'Device' && node.out_links.each do |n|
          #binding.pry if n.reference.name == "ad-de"
          last = layout_helper(out, last, node,
                   draw(n, out, path + [n.reference.name], flat, level+1, node)
                 )
        end

#        if n_kind == "Host"
#          out << ident(path, "}")
#        end
        true
      end

      def self.render_object_address(iface)
        tags = []
        out = []
        out << "name = \"#{iface.name}\""

        if iface.respond_to?(:mtu) && iface.mtu
          out << "mtu = \"#{iface.mtu}\""
        end
        if iface.kind_of? Construqt::Ipsecs::Ipsec
          out << "password = #{iface.password}"
          out << "transport_family = #{iface.transport_family}"
          out << "mtu_v4 = #{iface.mtu_v4}"
          out << "mtu_v6 = #{iface.mtu_v6}"
          out << "keyexchange = #{iface.keyexchange}"
        end
        binding.pry if name == 'ipsec'
        address = iface.address
        if iface.kind_of? Construqt::Flavour::IpsecVpnDelegate
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
            out << "route(#{idx}) = \"#{route.dst.to_string} via #{route.via.to_s}\""
          end
        end

        iface.delegate && iface.delegate.firewalls && iface.delegate.firewalls.each_with_index do |fw, idx|
          out << "fw(#{idx}) = \"#{fw.name}\""
        end

        iface.tags && (iface.tags+tags).sort.uniq.each_with_index do |tag, idx|
          out << "tag(#{idx}) = \"#{tag}\""
        end

        out.join("\n")
      end

      def self.clean_name(name)
        #name = name.gsub(/\s+/, '_')
        name.gsub(/[^0-9a-zA-Z_]/, '_')
      end

      def self.add_node_factory(type, host, *args)
        factory = {
          "BondDelegate.build_config" => lambda do |type, host, *args|
            args.first
          end,
          "BridgeDelegate.build_config" => lambda do |type, host, *args|
            args.first
          end,
          "DeviceDelegate.build_config" => lambda do |type, host, *args|
            #Construqt.logger.debug("DeviceDelegate.build_config:#{host.class.name} #{args.map{|i| i.name}}")
            args.first
          end,
          "HostDelegate.build_config" => lambda do |type, host, *args|
            #Construqt.logger.debug("GoJs:HostDelegate.build_config:#{host.name}")
            #binding.pry
            args.first
          end,
          "InterfaceDelegate.build_config" => lambda do |type, host, *args|
            nil
          end,
          "OpvnDelegate.build_config" => lambda do |type, host, *args|
            args.first
          end,
          "VlanDelegate.build_config" => lambda do |type, host, *args|
            args.first
          end,
          "WlanDelegate.build_config" => lambda do |type, host, *args|
            args.first
          end,
          "IpsecDelegate.build_config" => lambda do |type, host, *args|
            args.first.cfg
          end,
          "IpsecVpnDelegate.build_config" => lambda do |type, host, *args|
            args.first
          end,
          "VrrpDelegate.build_config" => lambda do |type, host, *args|
            args.first
          end,
          "GreDelegate.build_config" => lambda do |type, host, *args|
            args.first
          end,
          "BgpDelegate.build_config" => lambda do |type, host, *args|
            args.first.cfg
          end

        }

        method = factory[type]
        if method
          obj = method.call(type, host, *args)
          if obj
            ident = obj.ident
            throw "A object needs a ident #{obj.class.name}" unless ident
            TREE[ident] ||= Node.new(obj)
          end
        else
          Construqt.logger.debug "GoJs:add_node_factory type not found #{type}"
        end
      end

      def self.build_tree
        #binding.pry
        TREE.each do |ident, node|
          #binding.pry
          #Construqt.logger.debug "GoJs:build_tree=#{node.reference.class.name}=#{simple(node.reference.class)}"
          {
            "Vrrp" => lambda do |node|
              node.reference.delegate.interfaces.each do |i|
                node.connect TREE[i.ident]
              end
              node.reference.cable.connections.each do |c|
                node.wire_connect TREE[c.iface.ident]
              end
            end,
            "Vlan" => lambda do |node|
              node.reference.interfaces.each do |vlan_iface|
                node.connect TREE[vlan_iface.ident]
              end
              node.reference.cable.connections.each do |c|
                node.wire_connect TREE[c.iface.ident]
              end
            end,
            "Bond" => lambda do |node|
              node.reference.delegate.interfaces.each do |i|
                #Construqt.logger.debug(">>>>>>>>>> BOND -> #{simple(i.clazz)} #{i.name}")
                node.connect TREE[i.ident]
              end
              node.reference.cable.connections.each do |c|
                node.wire_connect TREE[c.iface.ident]
              end
            end,
            "Bridge" => lambda do |node|
              node.reference.delegate.interfaces.each do |i|
                #binding.pry
                node.connect TREE[i.ident]
              end
              node.reference.cable.connections.each do |c|
                #binding.pry
                node.wire_connect TREE[c.iface.ident]
              end
            end,
            "Wlan" => lambda do |node|
              if node.reference.master_if
                node.connect TREE[node.reference.master_if.ident]
              end
              node.reference.cable.connections.each do |c|
                node.wire_connect TREE[c.iface.ident]
              end
            end,
            "Device" => lambda do |node|
              node.reference.cable.connections.each do |c|
                #binding.pry
                node.wire_connect TREE[c.iface.ident]
              end
            end,
            "Template" => lambda do |node|
              #                iface.interface.delegate.vlans.each do |i|
              #                  iface.connect tree[simple(i.clazz)][i.name]
              #                end
            end,
            "Gre" => lambda do |node|
              #          binding.pry
              interface = node.reference.delegate.remote.interface
              node.connect TREE[interface.ident]
            end,
            "Opvn" => lambda do |node|
            end,
            "IpsecVpn" => lambda do |node|
              interface = node.reference.delegate.left_interface
              node.connect TREE[interface.ident]
            end,
            "Ipsec" => lambda do |node|
              [node.reference.lefts.first, node.reference.rights.first].each do |iface|
                binding.pry unless TREE[iface.interface.ident]
                node.connect TREE[iface.interface.ident]
              end
            end,
            "Bgp" => lambda do |node|
              #binding.pry
              [node.reference.lefts.first, node.reference.rights.first].each do |iface|
                node.connect TREE[iface.my.ident]
              end
            end,
            "Host" => lambda do |node|
              if node.reference.mother
                TREE[node.reference.mother.ident].connect node
              end
              node.reference.interfaces.values.each do |iface|
                next if simple(iface.class) == "Vrrp"
                Construqt.logger.debug "GoJs:Host:#{iface.name}:#{iface.ident}:#{simple(iface.class)}"
                node.connect TREE[iface.ident]
              end
            end

          }[simple(node.reference.class)].call(node)
        end
      end

      def self.layout_helper(out, last, node, drawed)
        return unless drawed
#        out << "#{last.ident} -down-> #{node.ident}" if last
        node
      end

      def self.call(type, *args)
        add_node_factory(type, *args)
        factory = {
          "completed" => lambda do |type, *args|
            build_tree
            gojs = {
              "class" => "go.GraphLinksModel",
              "linkFromPortIdProperty" => "fromPort",
              "linkToPortIdProperty" => "toPort",
              "nodeDataArray" => [],
              "linkDataArray" => []
            }
            last = nil
            TREE.values.each do |node|
              last = layout_helper(gojs["nodeDataArray"], last, node,
                                   draw(node, gojs["nodeDataArray"], [node.reference.name],
                                        ['Vrrp', 'Ipsec', 'Bgp'].include?(simple(node.reference.class))))
            end

            TREE.values.each { |n| n.drawed = false }
            TREE.values.each do |node|
              connect(node, gojs["linkDataArray"], [node.reference.name])
            end

            File.open("cfgs/world.gojs", 'w') do |file|
              file.write(JSON.pretty_generate(gojs))
            end
          end

        }
        Construqt.logger.debug "GoJs:#{type}"
        action = factory[type]
        if action
          action.call(type, *args)
        end
      end
    end
  end
end
