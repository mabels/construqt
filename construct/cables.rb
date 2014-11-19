
require 'construct/interfaces.rb'
require 'securerandom'
require 'construct/hostid.rb'

module Construct

class Cables

  def initialize(region)
    @region = region
    @cables = {}
  end
  def region
    @region
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
    attr_accessor :cable, :other
    def initialize(cable, other)
      self.cable = cable
      self.other = other
    end
  end

  def add(iface_left, iface_right)
#    throw "left should be a iface #{iface_left.class.name}" unless iface_left.kind_of?(Construct::Flavour::InterfaceDelegate)
#    throw "right should be a iface #{iface_right.class.name}" unless iface_right.kind_of?(Construct::Flavour::InterfaceDelegate)
    throw "left has a cable #{iface_left.cable}" if iface_left.cable
    throw "right has a cable #{iface_right.cable}" if iface_right.cable
    cable = Cable.new(iface_left, iface_right)
    throw "cable exists #{iface_left.cable}=#{iface_right.cable}" if @cables[cable.key]
    iface_left.cable = DirectedCable.new(cable, iface_right)
    iface_right.cable = DirectedCable.new(cable, iface_left)
    cable
	end

end
end
