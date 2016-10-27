module Construqt
  module Flavour
    module Delegate
      module InterfaceNode
        def init_node()
          @node = self.host.interface_graph.node_from_ref(self)
          self
        end

        def parents(ps)
          ps.each do |p|
            pnode = self.host.interface_graph.node_from_ref(p)
            pnode.join_as_child(@node)
          end
          self
        end
        def children(cn)
          cn.each do |c|
            cnode = self.host.interface_graph.node_from_ref(c)
            @node.join_as_child(cnode)
          end
          self
        end

        def node
          @node
        end

        def add_child(oth)
          @node.join_as_child(oth.node)
        end
      end
    end
  end
end
