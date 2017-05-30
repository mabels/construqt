module Construqt
  module Flavour

    class Node
      attr_accessor :reference
      def initialize(reference)
        self.reference = reference
        throw "Node need a ident #{reference.class.name}" unless reference.ident
        #throw "Node need a clazz #{reference.class.name}" unless reference.clazz
        #      self.clazz = clazz
        @in_links = {}
        @out_links = {}
        @wire_in_links = {}
        @wire_out_links = {}
        @drawed = false
      end

      def in_links
        @in_links.values
      end

      def out_links
        @out_links.values
      end

      def wire_in_links
        @wire_in_links.values
      end

      def wire_out_links
        @wire_out_links.values
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

      def wire_in_links=(node)
        @wire_in_links[node.object_id] = node
      end

      def in_links?(node)
        @in_links[node.object_id]
      end

      def wire_in_links?(node)
        @in_links[node.object_id]
      end

      def connect(node)
        unless node
          binding.pry
          throw "node not set"
        end
        unless self.in_links?(node)
          @out_links[node.object_id] = node
          node.in_links = self
        end
      end

      def wire_connect(node)
        throw "node not set" unless node
        unless self.wire_in_links?(node)
          @wire_out_links[node.object_id] = node
          node.wire_in_links = self
        end
      end
    end

  end
end
