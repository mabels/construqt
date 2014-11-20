require 'graphviz'

module Construct
  module Flavour
    module Graphviz

      def self.name
        'graphviz'
      end

      Flavour.add_aspect(self)

      @hosts = {}
      @g = GraphViz.new( :G, :type => :digraph )
      class Node
        attr_accessor :interface, :in_links, :out_links, :render_matrix, :clazz, :row, :span
        def initialize(clazz, interface)
          self.interface = interface
          self.clazz = clazz
          self.in_links = []
          self.out_links = []
          self.span = 0
        end

        def drawed!
          self.span += 1
          self.span >= 2
        end

        def drawed?
          self.span != 0
        end

        def connect(node)
          throw "node not set" unless node
          self.out_links << node
          node.in_links << self
        end
      end

      def self.simple(clazz)
        clazz.name[clazz.name.rindex(':')+1..-1]
      end

      class Row
        def initialize
          @row = []
        end

        def add_col(node)
          #node.drawed!
          @row << node
        end

        def get
          @row
        end
      end

      class Rows
        def initialize
          @rows = []
        end

        def get
          @rows
        end

        #    def get(row)
        #Construct.logger.debug "clazz=#{clazz} #{(@rows||{}).keys.inspect}"
        #      @rows[row] ||= Row.new
        #    end

        def add_col(level, node)
          @rows[level] ||= Row.new
          @rows[level].add_col(node)
        end
      end

      class RenderMatrix
        def add_node(node)
          @nodes ||= {}
          @nodes[node.object_id] = node
          self
        end

        def dim
          dim = @nodes.values.inject({}) do |r,node|
            r[node.clazz] ||= 0
            r[node.clazz] += node.out_links.length
          end

          OpenStruct.new :height => dim.length, :width => dim.values.max
        end
      end

      def self.search_render_matrix(node, result = {})
        result[node.render_matrix.object_id] = node.render_matrix if node.render_matrix
        node.out_links.each { |n| self.search_render_matrix(n, result) }
        result
      end

      def self.set_render_matrix(node, render_matrix)
        node.render_matrix = render_matrix.add_node(node)
        node.out_links.each { |n| self.set_render_matrix(n, render_matrix) }
      end

      def self.draw(node, rows, level)
        #binding.pry if node.interface.name == "sw10"
        return 0 if node.drawed!
        rows.add_col(level, node)
        ret = 0
        node.in_links.each do |in_link|
          #next if in_link.drawed
          #rows.add_col(in_link)
          ret = [ret, draw(in_link, rows, level-1)].max
        end

        node.out_links.each do |out_link|
          #next if out_link.drawed
          #rows.add_col(out_link)
          ret = [ret, draw(out_link, rows, level+1)].max
        end

        #if node.out_links.empty?
        #end

        [ret, node.out_links.length].max
      end

      def self.call(type, *args)
        factory = {
          "host.commit" => lambda do |type, host, *args|
            #binding.pry
            # vrrp -> bridge -> vlan -> bond -> device
            # vrrp1
            # vlan1 vlan2
            #      bond
            # device0 device1
            #

            tree = {}
            host.interfaces.each do |k,v|
              key = simple(v.clazz)
              tree[key] ||= {}
              tree[key][v.name] = Node.new(key,v)
            end

            tree.each do |k,ifaces|
              #          puts "K=>#{k}"
              ifaces.each do |name, iface|
                #            binding.pry if k == 'Bond'
                {
                  "Vrrp" => lambda do |iface|
                    interface = iface.interface.delegate.interface
                    iface.connect tree[simple(interface.clazz)][interface.name]
                  end,
                  "Vlan" => lambda do |iface|
                    interface = iface.interface.delegate.interface
                    iface.connect tree[simple(interface.clazz)][interface.name]
                  end,
                  "Bond" => lambda do |iface|
                    iface.interface.delegate.interfaces.each do |i|
                      #Construct.logger.debug(">>>>>>>>>> BOND -> #{simple(i.clazz)} #{i.name}")
                      iface.connect tree[simple(i.clazz)][i.name]
                    end
                  end,
                  "Bridge" => lambda do |iface|
                    iface.interface.delegate.interfaces.each do |i|
                      #binding.pry
                      iface.connect tree[simple(i.clazz)][i.name]
                    end
                  end,
                  "Device" => lambda do |iface|
                  end,
                  "Template" => lambda do |iface|
                    #                iface.interface.delegate.vlans.each do |i|
                    #                  iface.connect tree[simple(i.clazz)][i.name]
                    #                end
                  end,
                  "Gre" => lambda do |iface|
                  end,
                  "Opvn" => lambda do |iface|
                  end

                }[k].call(iface)
              end
            end

            #render_matrixs = []
            rows = Rows.new
            ["Vrrp","Vlan", "Bridge", "Bond", "Device"].each do |clazz|
              (tree[clazz]||{}).values.each do |node|
                next unless node.in_links.empty?
                next if node.drawed?
                draw(node, rows, 0)
              end
            end

            out = ['<','<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0">']
            out << "<TR><TD>#{host.name}</TD></TR>"
            #["Vrrp","Vlan", "Bridge", "Bond", "Device"].each do |clazz|
            #binding.pry
            rows.get.each do |row|
              #next if rows.get(clazz).nil? or rows.get(clazz).get.empty?
              out << "<TR>"
              row.get.each do |col|
                out << "<TD colspan='#{col.span > 1 ? (col.span-1) : 1}'>[#{col.interface.name}]</TD>"
              end

              out << "</TR>"
            end

            out << "</TABLE>"
            out << ">"
            #        cols = (5..13).map{|i| [i, (ifaces.length+1)%i] }.min{|a,b| a.last<=>b.last }.first
            #        ifaces.values.insert(ifaces.length/2, host).each_slice(cols).each do |line|
            #          out << "<TR>"
            #          line.each do |col|
            #            #binding.pry
            #            bgcolor = col.class.name.include?("Host") ? "grey" : "white"
            #            out << "<TD BGCOLOR='#{bgcolor}'>#{col.name}</TD>"
            #          end

            #          out << "</TR>"
            #        end

            @hosts[host.name] = @g.add_nodes( host.name , :shape => "record", :label => out.join("\n"))
          end,
          "completed" => lambda do |type, *args|
            @g.output( :svg => "cfgs/world.svg" )
          end

        }
        action = factory[type]
        if action
          action.call(type, *args)
        else
          #Construct.logger.debug "Graphviz:#{type}"
        end
      end
    end
  end
end
