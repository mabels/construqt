
module Construqt
  class Hosts
    module Grapher
      class Root
        attr_reader :name, :ident

        def initialize(name)
          @name = @ident = name
        end

        def host
          nil
        end

        def interfaces
          {}
        end

        def interface_graph
          nil
        end

        def commit
        end

        def region
          nil
        end

        def build_config(x, y, z)
        end
      end

      def self.build_hosts(hosts)
        graph = Graph.new(nil)
        root = graph.get_node(Root.new('construqt'))
        hosts.each do |host|
          # puts host.inspect
          # binding .pry
          graph.bind(host, root)
        end

        root
      end

      def self.disconnect(ifs, node)
        node.children.delete(ifs) && ifs.parents.delete(node)
      end

      #
      # D, [2016-10-18T15:34:08.987469 #69338] DEBUG -- : root
      # D, [2016-10-18T15:34:08.987526 #69338] DEBUG -- :   left
      # D, [2016-10-18T15:34:08.987594 #69338] DEBUG -- :     l1
      # D, [2016-10-18T15:34:08.987639 #69338] DEBUG -- :       lu1
      # D, [2016-10-18T15:34:08.987680 #69338] DEBUG -- :         lu2
      # D, [2016-10-18T15:34:08.987725 #69338] DEBUG -- :     l2
      # D, [2016-10-18T15:34:08.987784 #69338] DEBUG -- :       lu1
      # D, [2016-10-18T15:34:08.987805 #69338] DEBUG -- :         lu2
      # D, [2016-10-18T15:34:08.987864 #69338] DEBUG -- :   mid
      # D, [2016-10-18T15:34:08.987892 #69338] DEBUG -- :     lu2
      # D, [2016-10-18T15:34:08.987928 #69338] DEBUG -- :   right
      # D, [2016-10-18T15:34:08.987975 #69338] DEBUG -- :     r1
      # D, [2016-10-18T15:34:08.988006 #69338] DEBUG -- :       lu1
      # D, [2016-10-18T15:34:08.988041 #69338] DEBUG -- :         lu2
      # D, [2016-10-18T15:34:08.988068 #69338] DEBUG -- :     r2
      # D, [2016-10-18T15:34:08.988092 #69338] DEBUG -- :       lu1
      # D, [2016-10-18T15:34:08.988129 #69338] DEBUG -- :         lu2

      def self.build_interfaces(host)
        graph = Graph.new(nil)
        # root = graph.create_node(graph.find_ref(host))
        host.interfaces.values.each do |iface|
          my = graph.find_ref(iface)
          # root.join_as_child(my)
          # puts "my #{my.parents.map(&:ident).join(',')}>#{my.ident} top_mosts=#{Graph.top_mosts(my, root).map(&:ident).join(',')}"
          iface.children && iface.children.each do |ifs|
            # binding.pry
            inode = graph.find_ref(ifs)
            my.join_as_child(inode)
            puts "#{my.ident}->#{inode.ident}"
            # puts "child #{inode.parents.map(&:ident).join(',')}>#{inode.ident} "\
            #   "<=> #{my.parents.map(&:ident).join(',')}>#{my.ident}"\
            #   " top_mosts=#{Graph.top_mosts(inode, root).map(&:ident).join(',')}"
            #

          end

          iface.parents && iface.parents.each do |ifs|
            throw "not yet"
            # binding.pry
            # puts "parent #{my.ident} <=> #{ifs.ident}"
            # inode = graph.get_node(ifs, root)
            # disconnect(my, root)
            # my.parents.add inode
            # inode.children.add my
          end

          # my = graph.bind(iface, root)
          # binding.pry if iface.ident == "Bridge_cerberus_bridge0"
          iface.cable && iface.cable.connections.each do |cb|
            throw "not yet"
            # n_obj = graph.get_node(cb.iface)
            # n_obj.parents.add iface
            # my.children.add n_obj
          end
        end
        # root connector
        # host.interfaces.values.each do |iface|
        #   ref = graph.find_ref(iface)
        #   if ref.parents.empty?
        #   end
        #   # if ref.nodes.length == 1
        #   #   root.join_as_child(ref.nodes.find{|i| i.root})
        #   # else
        #   #   ref.nodes.delete(ref.nodes.find{|i| i.root})
        #   # end
        # end

        # Graph.dump(root, "iface(#{host.name})")
        # binding.pry
        [root, graph]
      end

      def self.build_simple_from_host(host)
        graph = Graph.new(nil)
        root = graph.get_node(host)
        host.interfaces.values.each do |iface|
          my = graph.get_node(iface, root)
          iface.children && iface.children.each do |ifs|
            # binding.pry
            inode = graph.get_node(ifs, root)
            # puts "child #{inode.parents.first.ident}>#{inode.ident} "\
            #   "<=> #{my.parents.first.ident}>#{my.ident}"
              # " top_mosts=#{top_mosts(inode).map(&:ident).join(',')}"

            disconnect(inode, root)
            my.children.add inode
            inode.parents.add my
          end

          iface.parents && iface.parents.each do |ifs|
            # binding.pry
            # puts "parent #{my.ident} <=> #{ifs.ident}"
            inode = graph.get_node(ifs, root)
            disconnect(my, root)
            my.parents.add inode
            inode.children.add my
          end
        end

        [root, graph]
      end
    end
  end
end
