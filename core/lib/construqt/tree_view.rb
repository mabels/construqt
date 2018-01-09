require 'rexml/document'
require 'rexml/element'
require 'rexml/cdata'

require_relative 'flavour/node'

module Construqt
    class TreeView
      def self.simple(clazz)
        #     clazz
        clazz.name[clazz.name.rindex(':')+1..-1].gsub(/Delegate$/,'')
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

      def self.clean_name(name)
        #name = name.gsub(/\s+/, '_')
        name.gsub(/[^0-9a-zA-Z_]/, '_')
      end

      def self.layout_helper(out, last, node, drawed)
        return unless drawed
#        out << "#{last.ident} -down-> #{node.ident}" if last
        node
      end

      attr_reader :tree, :single_wire

      def initialize
        @tree = {}
        @single_wire = {}
      end

      # def connect(node, out, path)
      #   return if node.drawed!
      #   #    Construqt.logger.debug("planuml.draw:#{node.reference.name} #{node.ident} ")
      #   node.out_links.each do |n|
      #     #      Construqt.logger.debug("planuml.draw:Out:#{node.reference.name} #{node.ident}:#{n.ident}")
      #     unless TreeView.simple(node.reference.class) == "Host"
      #       out << "#{node.ident} .. #{n.ident}"
      #     end
      #
      #     connect(n, out, path + [n.reference.name])
      #   end
      #   node.wire_out_links.each do |n|
      #     key = [node.ident,n.ident].sort.join('..')
      #     unless @single_wire[key]
      #       @single_wire[key] = true
      #       out << "#{node.ident} .. #{n.ident}"
      #     end
      #   end
      # end

      def add_node_factory(type, host, *args)
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
            #Construqt.logger.debug("Planuml:HostDelegate.build_config:#{host.name}")
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
          # "IpsecDelegate.build_config" => lambda do |type, host, *args|
          #   args.first.cfg
          # end,
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
          end,
          # "TunnelDelegate.build_config" => lambda do |type, host, *args|
          #   args.first
          # end,
          "Tunnel.build_config" => lambda do |type, host, *args|
            # binding.pry
            args.first
          end,
          "Endpoint.build_config" => lambda do |type, host, *args|
            # binding.pry
            args.first
          end
        }

        method = factory[type]
        if method
#Construqt.logger.debug "type:#{host.name}"
          obj = method.call(type, host, *args)
          if obj
            ident = obj.ident
            throw "A object needs a ident #{obj.class.name}" unless ident
            # binding.pry
            # Construqt.logger.debug "TreeView:add_node_factory #{type}:#{ident}"
            @tree[ident] ||= Flavour::Node.new(obj)
          end
        else
          # Construqt.logger.debug "TreeView:add_node_factory type not found #{type}:#{host.name}:#{args}"
          # binding.pry
        end
      end

      def build_tree
        #binding.pry
        @tree.each do |ident, node|
          #binding.pry
          #Construqt.logger.debug "Planuml:build_tree=#{node.reference.class.name}=#{simple(node.reference.class)}"
          {
            "Vrrp" => lambda do |node|
              node.reference.delegate.interfaces.each do |i|
                node.connect @tree[i.ident]
              end
              binding.pry if node.reference.cable.nil?
              node.reference.cable.connections.each do |c|
                node.wire_connect @tree[c.iface.ident]
              end
            end,
            "Vlan" => lambda do |node|
              node.reference.interfaces.each do |vlan_iface|
                node.connect @tree[vlan_iface.ident]
              end
              node.reference.cable.connections.each do |c|
                node.wire_connect @tree[c.iface.ident]
              end
            end,
            "Bond" => lambda do |node|
              node.reference.delegate.interfaces.each do |i|
                #Construqt.logger.debug(">>>>>>>>>> BOND -> #{simple(i.clazz)} #{i.name}")
                node.connect @tree[i.ident]
              end
              node.reference.cable.connections.each do |c|
                node.wire_connect @tree[c.iface.ident]
              end
            end,
            "Bridge" => lambda do |node|
              node.reference.delegate.interfaces.each do |i|
                #binding.pry
                node.connect @tree[i.ident]
              end
              node.reference.cable.connections.each do |c|
                #binding.pry
                node.wire_connect @tree[c.iface.ident]
              end
            end,
            "Wlan" => lambda do |node|
              if node.reference.master_if
                node.connect @tree[node.reference.master_if.ident]
              end
              node.reference.cable.connections.each do |c|
                node.wire_connect @tree[c.iface.ident]
              end
            end,
            "Device" => lambda do |node|
              node.reference.cable.connections.each do |c|
                #binding.pry
                node.wire_connect @tree[c.iface.ident]
              end
              binding.pry if node.reference.cable.nil?
            end,
            "Template" => lambda do |node|
              #                iface.interface.delegate.vlans.each do |i|
              #                  iface.connect tree[simple(i.clazz)][i.name]
              #                end
            end,
            "Gre" => lambda do |node|
              # @tree[node.reference.endpoint.ident].connect node
              #node.reference.endpoint.remote.interfaces.each do |iface|
              # node.connect @tree[node.reference.endpoint.tunnel.ident]
              #end
            end,
            "Opvn" => lambda do |node|
            end,
            "IpsecVpn" => lambda do |node|
              interface = node.reference.delegate.left_interface
              node.connect @tree[interface.ident]
            end,
            "Tunnel" => lambda do |node|
                # node.connect @tree[node.reference.endpoint.tunnel.ident]
                # node.connect @tree[node.reference.endpoint.tunnel.ident]
                node.reference.endpoints.each do |ep|
                    node.connect @tree[ep.ident]
                end
            end,
            "Endpoint" => lambda do |node|
              #@tree[node.reference.host.ident].connect node
                #node.connect @tree[node.reference.host.ident]
                # binding.pry
                node.reference.interfaces.each do |iface|
                #  if @tree[iface.ident]
                    node.connect @tree[iface.ident]
                #  end
                end
            end,
            #"Ipsec" => lambda do |node|
            #  [node.reference.lefts.first, node.reference.rights.first].each do |iface|
            #    if @tree[iface.interface.ident]
            #      node.connect @tree[iface.interface.ident]
            #    end
            #  end
            #end,
            "Bgp" => lambda do |node|
              #binding.pry
              [node.reference.lefts.first, node.reference.rights.first].each do |iface|
                node.connect @tree[iface.my.ident]
              end
            end,
            "Host" => lambda do |node|
              if node.reference.mother
                @tree[node.reference.mother.ident].connect node
              end
              node.reference.interfaces.values.each do |iface|
                next if TreeView.simple(iface.class) == "Vrrp"
                # Construqt.logger.debug "Planuml:Host:#{iface.name}:#{iface.ident}:#{Plantuml.simple(iface.class)}"
                node.connect @tree[iface.ident]
              end
            end

          }[TreeView.simple(node.reference.class)].call(node)
        end
      end


    end
end
