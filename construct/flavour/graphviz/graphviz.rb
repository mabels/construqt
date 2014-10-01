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
        out = ['<','<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0">']
        ifaces = host.interfaces.select do |k,v| 
          v.clazz.name[v.clazz.name.rindex(':')+1..-1]=="Device"
        end
        cols = (5..13).map{|i| [i, (ifaces.length+1)%i] }.min{|a,b| a.last<=>b.last }.first
        ifaces.values.insert(ifaces.length/2, host).each_slice(cols).each do |line|
          out << "<TR>"
          line.each do |col|
            #binding.pry
            bgcolor = col.class.name.include?("Host") ? "grey" : "white"
            out << "<TD BGCOLOR='#{bgcolor}'>#{col.name}</TD>"
          end
          out << "</TR>"
        end
        out << "</TABLE>"
        out << ">"
        @hosts[host.name] = @g.add_nodes( host.name , :shape => "record",
                                         :label => out.join("\n"))
      end,
      "completed" => lambda do |type, *args|
        @g.output( :svg => "cfgs/world.svg" )
      end
    }
    action = factory[type] 
    if action
      action.call(type, *args)
    else
      Construct.logger.debug "Graphviz:#{type}" 
    end
  end

end
end
end
