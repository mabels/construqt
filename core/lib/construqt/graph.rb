require 'set'
module Construqt
    class Graph

      class Visited
        def initialize(key)
          @key = key
          # @sessions = sessions
        end
        def used(session)
          session[@key]
        end
        def set_used(session)
          session[@key] = true
        end
      end

      class Link
        attr_reader :param, :link
        def initialize(link, param)
          @link = link;
          @param = param;
        end
      end

      class Node
        attr_reader :ref, :children, :parents, :param
        def initialize(graph, ref)
          throw "Ref should not be a Node" if ref.kind_of?(Node)
          @ref = ref
          @graph = graph
          @param = graph.create_link_param(ref, ref)
          @children = Set.new
          @parents = Set.new
        end

        def inspect
          "#<#{self.class.name} ref=#{@ref.ident} param=#{@param.inspect} children=#{@children.map{|i| i.link.ident}.join(",")} parents=#{@parents.map{|i| i.link.ident}.join(",")}>"
        end


        def ident
          @ref.ident
        end

        def join_as_child(oth)
          left, right = @graph.create_link_pair(self, oth)
          self.children.add right
          oth.parents.add left
          [self, oth]
        end
      end

      attr_reader :nodes
      def initialize
        @nodes = {}
        # @linkparams = []
      end

      def create_link_param(left, right)
        key = [left.ident,right.ident].sort.join("<=>")
        ret = Visited.new(key)
        # @linkparams.push ret
        ret
      end


      def create_link_pair(left, right)
        lp = create_link_param(left, right)
        [Link.new(left, lp), Link.new(right, lp)]
      end

      def node_from_ref(ref)
        @nodes[ref.ident] ||= Node.new(self, ref)
      end

      def find_start(session)
        ret = @nodes.values.find do |node|
          !node.param.used(session) &&
          node.parents.empty? && (
            node.children.empty? ||
            node.children.find{|i| !i.param.used(session)}
          )
        end
        puts "find_start=>#{!ret || ret.ident}"
        ret
      end

      def walk(session, stop, base, level, &block)
        #throw "illegal graph" if level < 0
        if !base.children.empty?
          base.parents.each do |parent|
            next if parent.link == stop
            # next if parent.link
            next if parent.param.used(session)
            parent.param.set_used(session)
            # puts "#{level}-#{stop.ident}==#{parent.link.ident}-parent-enter"
            walk(session, base, parent.link, level-1, &block)
            # puts "#{level}-#{stop.ident}==#{parent.link.ident}-parent-leave"
          end
          base.param.set_used(session)
          block.call(base, level)
        else
          if !base.parents.find{|i| !i.param.used(session)}
            base.param.set_used(session)
            block.call(base, level)
          end
        end
        # puts "#{level}-leave"
        base.children.each do |child|
          next if child.link == stop
          next if child.param.used(session)
          child.param.set_used(session)
          # puts "#{level}-#{stop.ident}==#{child.link.ident}-child-enter"
          walk(session, child.link, child.link, 1+level, &block)
          # puts "#{level}-#{stop.ident}==#{child.link.ident}-child-leave"
        end
      end

      def run_session(&block)
          #session = @session += 1
          block.call({})
          #@sessions.delete(session)
      end


      def dump
        run_session do |session|
          # should be while
          while (base = find_start(session))
            # binding.pry
            walk(session, base, base, 0) do |node, level|
              puts "****#{level}-#{Util.indent(node.ident, 2*level)}"
            end
          end
        end
      end

      def self.build_from_host(host)
        graph = Graph.new
        host.interfaces.values.each do |iface|
          my = graph.node_from_ref(iface)
          iface.children && iface.children.each do |ifs|
            inode = graph.node_from_ref(ifs)
            my.join_as_child(inode)
          end

          iface.parents && iface.parents.each do |ifs|
            pnode = graph.node_from_ref(ifs)
            pnode.join_as_child(my)
            # binding.pry
          end
        end
        graph.run_session do |session|
          while (base = graph.find_start(session))
            graph.walk(session, base, base, 0) do |node, level|
              return nil if level < 0
            end
          end
        end
        graph
      end

      def flat
        ret = []
        run_session do |session|
          # should be while
          while (base = find_start(session))
            flat = []
            ret.push flat
            walk(session, base, base, 0) do |node, level|
              flat.push(node)
              # puts "****#{level}-#{Util.indent(node.ident, 2*level)}"
            end
          end
        end
        ret
      end



    end
end
