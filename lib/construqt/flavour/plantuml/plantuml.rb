
module Construqt
  module Flavour
    module Plantuml

      def self.name
        'plantuml'
      end

      Flavour.add_aspect(self)
      def self.simple(clazz)
        #     clazz
        clazz.name[clazz.name.rindex(':')+1..-1].gsub(/Delegate$/,'')
      end

      class Node
        attr_accessor :reference
        def initialize(reference)
          self.reference = reference
          throw "Node need a ident #{reference.class.name}" unless reference.ident
          #throw "Node need a clazz #{reference.class.name}" unless reference.clazz
          #      self.clazz = clazz
          @in_links = {}
          @out_links = {}
          @drawed = false
        end

        def in_links
          @in_links.values
        end

        def out_links
          @out_links.values
        end

        def ident
          reference.ident
        end

        def drawed=(a)
          @drawed = a
        end

        def drawed!
          prev = @drawed
          @drawed = true
          prev
        end

        def drawed?
          @drawed
        end

        def in_links=(node)
          @in_links[node.object_id] = node
        end

        def in_links?(node)
          @in_links[node.object_id]
        end

        def connect(node)
          throw "node not set" unless node
          unless self.in_links?(node)
            @out_links[node.object_id] = node
            node.in_links = self
          end
        end
      end

      @tree = {}

      def self.connect(node, out, path)
        return if node.drawed!
        #    Construqt.logger.debug("planuml.draw:#{node.reference.name} #{node.ident} ")
        node.out_links.each do |n|
          #      Construqt.logger.debug("planuml.draw:Out:#{node.reference.name} #{node.ident}:#{n.ident}")
          unless simple(node.reference.class) == "Host"
            out << "#{node.ident} .. #{n.ident}"
          end

          connect(n, out, path + [n.reference.name])
        end
      end

      def self.ident(path, content)
        ident = (0...path.length-1).to_a.map{ " " }.join('')
        content.lines.map{|i| ident+i }.join('')
      end

      def self.draw(node, out, path, flat)
        return if node.drawed!
        n_kind = simple(node.reference.class)
        if n_kind == "Host"
          out << ident(path, "package \"#{node.ident}\" <<Node>> #DDDDDD {")
        else
          out << ident(path, <<UML)
object #{node.ident} <<#{n_kind}>> {
          #{render_object_address(node.reference)}
}
UML
        end

        !flat && n_kind != 'Device' && node.out_links.each do |n|
          draw(n, out, path + [n.reference.name], flat)
        end

        if n_kind == "Host"
          out << ident(path, "}")
        end
      end

      def self.render_object_address(iface)
        out = []
        out << "name = \"#{iface.name}\""
        out << "desc = \"#{iface.description}\"" if iface.description
        if iface.address
          tags = []
          [iface.address.v4s, iface.address.v6s].each do |ips|
            next unless ips.first
            prefix = ips.first.ipv4? ? "ipv4" : "ipv6"
            ips.each_with_index do |ip, idx|
              tags += Construqt::Tags.from(ip)||[]
              out << "#{prefix}(#{idx}) = #{ip.to_string}"
            end
          end
          if iface.address.dhcpv4?
            out << "dhcpv4 = client"
          end
          if iface.address.dhcpv6?
            out << "dhcpv6 = client"
          end

          iface.address.routes.each_with_index do |route, idx|
            out << "route(#{idx}) = \"#{route.dst.to_string} via #{route.via.to_s}\""
          end
          iface.delegate.firewalls && iface.delegate.firewalls.each_with_index do |fw, idx|
            out << "fw(#{idx}) = \"#{fw.name}\""
          end
          (iface.tags+tags).sort.uniq.each_with_index do |tag, idx|
            out << "tag(#{idx}) = \"#{tag}\""
          end
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
          "IpsecDelegate.build_config" => lambda do |type, host, *args|
            args.first.cfg
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
            @tree[ident] ||= Node.new(obj)
          end
        else
          Construqt.logger.debug "Planuml:add_node_factory type not found #{type}"
        end
      end

      def self.build_tree
        #binding.pry
        @tree.each do |ident,node|
          #binding.pry
          #      Construqt.logger.debug "Planuml:build_tree=#{node.reference.class.name}=#{simple(node.reference.class)}"
          {
            "Vrrp" => lambda do |node|
              node.reference.delegate.interfaces.each do |i|
                node.connect @tree[i.ident]
              end
            end,
            "Vlan" => lambda do |node|
              node.reference.interfaces.each do |vlan_iface|
                node.connect @tree[vlan_iface.ident]
              end
            end,
            "Bond" => lambda do |node|
              node.reference.delegate.interfaces.each do |i|
                #Construqt.logger.debug(">>>>>>>>>> BOND -> #{simple(i.clazz)} #{i.name}")
                node.connect @tree[i.ident]
              end
            end,
            "Bridge" => lambda do |node|
              node.reference.delegate.interfaces.each do |i|
                #binding.pry
                node.connect @tree[i.ident]
              end
            end,
            "Device" => lambda do |node|
              if node.reference.cable
                node.connect @tree[node.reference.cable.other.ident]
              end
            end,
            "Template" => lambda do |node|
              #                iface.interface.delegate.vlans.each do |i|
              #                  iface.connect tree[simple(i.clazz)][i.name]
              #                end
            end,
            "Gre" => lambda do |node|
              #          binding.pry
              interface = node.reference.delegate.local.interface
              node.connect @tree[interface.ident]
            end,
            "Opvn" => lambda do |node|
            end,
            "Ipsec" => lambda do |node|
              [node.reference.left, node.reference.right].each do |iface|
                binding.pry unless @tree[iface.interface.ident]
                node.connect @tree[iface.interface.ident]
              end
            end,
            "Bgp" => lambda do |node|
              #binding.pry
              [node.reference.left, node.reference.right].each do |iface|
                node.connect @tree[iface.my.ident]
              end
            end,
            "Host" => lambda do |node|
              node.reference.interfaces.values.each do |iface|
                next if simple(iface.class) == "Vrrp"
                #Construqt.logger.debug "Planuml:Host:#{iface.name}:#{iface.ident}:#{simple(iface.class)}"
                node.connect @tree[iface.ident]
              end
            end

          }[simple(node.reference.class)].call(node)
        end
      end

      #X         #render_matrixs = []
      #X         #[i"Vrrp","Vlan", "Bridge", "Bond", "Device"].each do |clazz|
      #X         tree.keys.each do |clazz|
      #X            (tree[clazz]||{}).values.each do |node|
      #X              next unless node.in_links.empty?
      #X              next if node.drawed?
      #X              draw(node, out, [node.reference.name])
      #X            end

      #X         end

      #X         out << <<UML
      #X }
      #X  end

      #
      def self.call(type, *args)
        add_node_factory(type, *args)
        factory = {
          #X       "host.commit" => lambda do |type, host, *args|
          #X         #binding.pry
          #X         # vrrp -> bridge -> vlan -> bond -> device
          #X         # vrrp1
          #X         # vlan1 vlan2
          #X         #      bond
          #X         # device0 device1
          #X         #
          #X         out = []
          #X
          #X         out << <<UML
          #X package "#{host.name}" {
          #X UML
          #X         tree = {}
          #X         host.interfaces.each do |k,v|
          #X           key = simple(v.clazz)
          #X           tree[key] ||= {}
          #X           ident = "#{clean_name(host.name)}_#{key}_#{clean_name(v.name)}"
          #X           tree[key][v.name] = Node.new(key, ident, v)
          #X           out << <<UML
          #X object #{ident} {
          #X #{render_object_address(v)}
          #X }
          #X UML
          #X         end

          #X
          #X         tree.each do |k,ifaces|
          #X #          puts "K=>#{k}"
          #X           ifaces.each do |name, iface|
          #X #            binding.pry if k == 'Bond'
          #X             {
          #X               "Vrrp" => lambda do |iface|
          #X                 interface = iface.interface.delegate.interface
          #X                 iface.connect tree[simple(interface.clazz)][interface.name]
          #X               end,
          #X               "Vlan" => lambda do |iface|
          #X                 iface.interface.interfaces.each do |vlan_iface|
          #X                   iface.connect tree[simple(vlan_iface.clazz)][vlan_iface.name]
          #X                 end

          #X               end,
          #X               "Bond" => lambda do |iface|
          #X                 iface.interface.delegate.interfaces.each do |i|
          #X                   #Construqt.logger.debug(">>>>>>>>>> BOND -> #{simple(i.clazz)} #{i.name}")
          #X                   iface.connect tree[simple(i.clazz)][i.name]
          #X                 end

          #X               end,
          #X               "Bridge" => lambda do |iface|
          #X                 iface.interface.delegate.interfaces.each do |i|
          #X                   #binding.pry
          #X                   iface.connect tree[simple(i.clazz)][i.name]
          #X                 end

          #X               end,
          #X               "Device" => lambda do |iface|
          #X               end,
          #X               "Template" => lambda do |iface|
          #X #                iface.interface.delegate.vlans.each do |i|
          #X #                  iface.connect tree[simple(i.clazz)][i.name]
          #X #                end

          #X               end,
          #X               "Gre" => lambda do |iface|
          #X                 interface = iface.interface.delegate.local.interface
          #X            #     puts ">>>>>>GRE #{interface.host.name} #{interface.name}"
          #X                 iface.connect tree[simple(interface.clazz)][interface.name]
          #X               end,
          #X               "Opvn" => lambda do |iface|
          #X               end

          #X             }[k].call(iface)
          #X           end

          #X         end

          #X
          #X         #render_matrixs = []
          #X         #[i"Vrrp","Vlan", "Bridge", "Bond", "Device"].each do |clazz|
          #X         tree.keys.each do |clazz|
          #X            (tree[clazz]||{}).values.each do |node|
          #X              next unless node.in_links.empty?
          #X              next if node.drawed?
          #X              draw(node, out, [node.reference.name])
          #X            end

          #X         end

          #X         out << <<UML
          #X }
          #X UML
          "completed" => lambda do |type, *args|
            build_tree
            out = []
            #        @tree.values.each do |node|
            #binding.pry if node.reference.name == "s2b-l3-m2"
            #           out << <<UML
            #object #{node.ident} {
            #           #{render_object_address(node.reference)}
            #}
            #UML
            #        end

            @tree.values.each do |node|
              #           next unless node.in_links.empty?
              draw(node, out, [node.reference.name], ['Vrrp', 'Ipsec', 'Bgp'].include?(simple(node.reference.class)))
            end

            @tree.values.each { |n| n.drawed = false }
            @tree.values.each do |node|
              #           next unless node.in_links.empty?
              connect(node, out, [node.reference.name])
            end

            File.open("cfgs/world.puml", 'w') do |file|
              file.puts(<<UML)
@startuml
skinparam object {
  ArrowColor<<Gre>> MediumOrchid
  BackgroundColor<<Gre>> MediumOrchid
  ArrowColor<<Bgp>> MediumSeaGreen
  BackgroundColor<<Bgp>> MediumSeaGreen
  ArrowColor<<Ipsec>> LightSkyBlue
  BackgroundColor<<Ipsec>> LightSkyBlue
  ArrowColor<<Vrrp>> OrangeRed
  BackgroundColor<<Vrrp>> OrangeRed
  ArrowColor<<Device>> YellowGreen
  BackgroundColor<<Device>> YellowGreen
  ArrowColor<<Bond>> Orange
  BackgroundColor<<Bond>> Orange
  ArrowColor<<Vlan>> Yellow
  BackgroundColor<<Vlan>> Yellow
  ArrowColor<<Bridge>> Pink
  BackgroundColor<<Bridge>> Pink
}
skinparam stereotypeBackgroundColor<<Gre>> MediumOrchid
skinparam stereotypeBackgroundColor<<Bgp>> MediumSeaGreen
skinparam stereotypeBackgroundColor<<Ipsec>> LightSkyBlue
skinparam stereotypeBackgroundColor<<Vrrp>> OrangeRed
skinparam stereotypeBackgroundColor<<Device>> YellowGreen
skinparam stereotypeBackgroundColor<<Bond>> Orange
skinparam stereotypeBackgroundColor<<Vlan>> Yellow
skinparam stereotypeBackgroundColor<<Bridge>> Pink
UML
              file.write(out.join("\n") + "\n")
              file.puts("@enduml")
            end

            if File.exists?("/cygdrive/c/Program Files/cygwin/bin/dot.exe")
              dot = "C:\\Program Files\\cygwin\\bin\\dot.exe"
            elsif File.exists?("/usr/bin/dot")
              dot = "/usr/bin/dot"
            else
              dot = "$(which dot)"
            end
            if  File.exists?("#{ENV['HOMEPATH']}/Downloads/plantuml.jar")
              plantuml_jar = "#{ENV['HOMEPATH']}/Downloads/plantuml.jar"
            else
               plantuml_jar = "$HOME/Downloads/plantuml.jar"
            end
            system("java -jar \"#{plantuml_jar}\" -Djava.awt.headless=true -graphvizdot \"#{dot}\" -tsvg cfgs/world.puml")
          end

        }
        Construqt.logger.debug "Planuml:#{type}"
        action = factory[type]
        if action
          action.call(type, *args)
        end
      end
    end
  end
end
