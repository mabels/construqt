
module Construqt

  class Cables
    class Plugin

      def iface(iface)
        @iface = iface
        self
      end
      def get_iface
        @iface
      end

      def get_type
        @type || "veth"
      end

      def type_phys
        @type = "phys"
        self
      end


      class SingleCable
        def is_plugable?
          not @cable
        end
        def plug(cable)
          throw "a nil cable is not a cable" unless cable
          @cable = cable
        end
        def connections
          if @cable
            [@cable]
          else
            []
          end
        end
      end
      module Single
        def cable
          @cable ||= SingleCable.new
        end
      end
      class MultipleCable
        def is_plugable?
          true
        end
        def plug(cable)
          throw "a nil cable is not a cable" unless cable
          @cables ||= []
          @cables << cable
        end
        def connections
          @cables ||= []
        end
      end
      module Multiple
        def cable
          @cable ||= MultipleCable.new
        end
      end
    end

    attr_reader :region, :cables
    def initialize(region)
      @region = region
      @cables = {}
    end

    class Cable
      attr_reader :left, :right
      def initialize(left, right)
        @left = left
        @right = right
      end

      def key
        [left.name, right.name].sort.join("<=>")
      end
    end

    class DirectedCable
      attr_accessor :cable, :iface
      def initialize(cable, iface)
        self.cable = cable
        self.iface = iface
      end
      def ident
        self.cable.key
      end
    end

    def add(iface_left, iface_right)
      #    throw "left should be a iface #{iface_left.class.name}" unless iface_left.kind_of?(Construqt::Flavour::InterfaceDelegate)
      #    throw "right should be a iface #{iface_right.class.name}" unless iface_right.kind_of?(Construqt::Flavour::InterfaceDelegate)
      throw "left has a cable #{iface_left.cable}" unless iface_left.cable.is_plugable?
      throw "right has a cable #{iface_right.cable}" unless iface_right.cable.is_plugable?
      cable = Cable.new(iface_left, iface_right)
      throw "cable exists #{iface_left.cable}=#{iface_right.cable}" if @cables[cable.key]
      iface_left.cable.plug(DirectedCable.new(cable, iface_right))
      iface_right.cable.plug(DirectedCable.new(cable, iface_left))
      cable
    end
  end
end
