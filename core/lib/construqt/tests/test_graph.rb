

require 'pry'

require 'test/unit'

require 'ruby-prof'

#RubyProf.start

#$LOAD_PATH.unshift(File.dirname(__FILE__))
#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'../../../../'
[
  "#{CONSTRUQT_PATH}/construqt/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ubuntu/lib",
  "#{CONSTRUQT_PATH}/ipaddress/ruby/lib"
].each {|path| $LOAD_PATH.unshift(path) }
require 'construqt'

class GraphTest < Test::Unit::TestCase
  class Host
    attr_accessor :interfaces, :ident, :name
    def initialize(name)
      @ident = @name = name
      @interfaces = {}
    end
  end
  class Interface
    include Construqt::Cables::Plugin::Multiple
    attr_reader :children, :ident, :name, :parents
    def initialize(name)
      @ident = @name = name
      @children = []
      @parents = []
    end
  end
  class Vlan < Interface
  end
  class Bridge < Interface
  end

  def host_interfaces(ifs)
    ret = {}
    ifs.each do |iface|
      ret[iface.name] = iface
    end
    ret
  end
  def off_test_empty
    host = Host.new("root")
    host.interfaces = host_interfaces []
    ret = Construqt::Graph.root_first_list(Construqt::Hosts::Grapher.build_interfaces(host).first)
    assert_equal(ret.map{|i|i.ident}, ["root"])
  end
  def off_test_flat_empty
    host = Host.new("root")
    host.interfaces = host_interfaces [
      Interface.new("dev0"),
      Interface.new("dev1"),
      Interface.new("dev2"),
      Interface.new("dev3")
    ]
    ret = Construqt::Graph.root_first_list(Construqt::Hosts::Grapher.build_interfaces(host).first)
    assert_equal(ret.map{|i|i.ident}, ["root", "dev0", "dev1", "dev2", "dev3"])
  end

  def xx_test_simple_vlans_parent
    host = Host.new("root")
    dev0 = Interface.new("dev0")
    vlan0 = Vlan.new("vlan0")
    vlan0.parents.push dev0
    dev1 = Interface.new("dev1")
    vlan1 = Vlan.new("vlan1")
    vlan1.parents.push dev1

    host.interfaces = host_interfaces [vlan1, dev0, vlan0, dev1]
    ret = Construqt::Graph.root_first_list(Construqt::Hosts::Grapher.build_interfaces(host))
    assert_equal(ret.map{|i|i.ident}, ["root", "dev1", "vlan1", "dev0", "vlan0"])
  end

  def xx_test_simple_bridge_children
    host = Host.new("root")
    dev0 = Interface.new("dev0")
    br0 = Bridge.new("br0")
    br0.children.push dev0
    dev1 = Interface.new("dev1")
    br1 = Bridge.new("br1")
    br1.children.push dev1
    host.interfaces = host_interfaces [br1,dev0, br0, dev1]
    ret = Construqt::Graph.root_first_list(Construqt::Hosts::Grapher.build_interfaces(host))
    assert_equal(ret.map{|i|i.ident}, ["root", "br1", "dev1", "br0", "dev0"])
  end

  def off_create_host
    #   root
    #  left  right mid
    # l1 l2  r1 r2  lu1
    #   lu1    lu2
    #   lu2
    host = Host.new("root")
    left = Interface.new("left")
    mid = Interface.new("mid")
    right = Interface.new("right")

    l1 = Interface.new("l1")
    l2 = Interface.new("l2")
    r1 = Interface.new("r1")
    r2 = Interface.new("r2")

    lu1 = Interface.new("lu1")
    lu2 = Interface.new("lu2")
    lu3 = Interface.new("lu3")

    left.children.push l1
    left.children.push l2

    l1.children.push lu1
    l2.children.push lu1
    lu1.children.push lu2

    right.children.push r1
    right.children.push r2
    r1.children.push lu1
    r2.children.push lu1

    mid.children.push lu2
    lu2.children.push lu3
    host.interfaces = host_interfaces [left,mid,right,lu3, l1,l2,r1,r2, lu1, lu2]
    host
  end

  def off_test_top_mosts

    root, graph = Construqt::Hosts::Grapher.build_simple_from_host(create_host)
    # Construqt::Graph.dump(root)

    graph.visited.values.each do |n|
      next if n == root
      res = Construqt::Graph.top_mosts(n, root).map{|i|i.ident}
      #puts "#{n.ident}:#{Construqt::Graph.top_mosts(n, root).map{|i|i.ident}.join(",")}"
      case n.ident
      when "left"
        assert_equal ["left"], res
      when "l1"
        assert_equal ["left"], res
      when "l2"
        assert_equal ["left"], res
      when "mid"
        assert_equal ["mid"], res
      when "lu2"
        assert_equal ["mid","left","right"], res
      when "right"
        assert_equal ["right"], res
      when "r1"
        assert_equal ["right"], res
      when "r2"
        assert_equal ["right"], res
      when "lu1"
        assert_equal ["left","right"], res
      end
      # puts n.ident
    end
  end

  def off_test_contains
    root, graph = Construqt::Hosts::Grapher.build_simple_from_host(create_host)
    Construqt::Graph.dump(root)
    graph.visited.values.each do |n|
      cts = Construqt::Graph.contains(n)
      res = cts.map{|i|i.ident}
      # puts "#{n.ident}=> #{cts.map{|i|i.ident.inspect}.join(",")}"
      case n.ident
      when "root"
        assert_equal res, ["root","left","l1","lu1","lu2","l2","mid","right","r1","r2"]
      when "left"
        assert_equal res, ["left","l1","lu1","lu2","l2"]
      when "l1"
        assert_equal res, ["l1","lu1","lu2"]
      when "l2"
        assert_equal res, ["l2","lu1","lu2"]
      when "mid"
        assert_equal res, ["mid","lu2"]
      when "lu2"
        assert_equal res, ["lu2"]
      when "right"
        assert_equal res, ["right", "r1", "lu1", "lu2", "r2"]
      when "r1"
        assert_equal res, ["r1", "lu1", "lu2"]
      when "r2"
        assert_equal res, ["r2","lu1","lu2"]
      when "lu1"
        assert_equal res, ["lu1","lu2"]
      end
    end
  end


  def off_test_interface_graph
    root, graph = Construqt::Hosts::Grapher.build_interfaces(create_host)
    graph.visited.values.each do |n|
      next if n == root
      res = Construqt::Graph.top_mosts(n, root).map{|i|i.ident}
      #puts "#{n.ident}:#{Construqt::Graph.top_mosts(n, root).map{|i|i.ident}.join(",")}"
      case n.ident
      when "left"
        assert_equal ["left"], res
      when "l1"
        assert_equal ["left"], res
      when "l2"
        assert_equal ["left"], res
      when "mid"
        assert_equal ["mid"], res
      when "lu2"
        assert_equal ["mid","left","right"], res
      when "right"
        assert_equal ["right"], res
      when "r1"
        assert_equal ["right"], res
      when "r2"
        assert_equal ["right"], res
      when "lu1"
        assert_equal ["left","right"], res
      end
      # puts n.ident
    end

  end

  def looped_graph
    #   root
    #  left  right mid
    # l1 l2  r1 r2  lu1
    #   lu1    lu2
    #   lu2
    host = Host.new("root")
    left = Interface.new("left")
    mid = Interface.new("mid")
    right = Interface.new("right")

    l1 = Interface.new("l1")
    l2 = Interface.new("l2")
    l3 = Interface.new("l3")
    l4 = Interface.new("l4")

    r1 = Interface.new("r1")
    r2 = Interface.new("r2")
    r3 = Interface.new("r3")
    r4 = Interface.new("r4")

    left.children.push l1
    l1.children.push l2
    l2.children.push l3
    l3.children.push l4

    right.children.push r1
    r1.children.push l4
    l4.children.push r2
    r2.children.push l2
    l2.children.push r3
    r3.children.push r4

    mid.children.push r1
    r1.children.push r2
    r2.children.push l2
    l2.children.push r3
    r3.children.push r4

    host.interfaces = host_interfaces [
      left,mid,right, l1,l2,l3,l4, r1,r2,r3,r4
    ]
    host
  end


  def xx_test_looped_grap
    host = looped_graph
    root,graph = Construqt::Hosts::Grapher.build_interfaces(host)
    binding.pry
    Construqt::Graph.dump(root)


  end

  def valid_graph
    host = Host.new("root")
    eth0 = Interface.new("eth0")
    eth1 = Interface.new("eth1")
    bond0 = Interface.new("bond0")
    br0 = Interface.new("br0")
    d0 = Interface.new("d0")
    vlan24 = Interface.new("vlan24")
    vlan7 = Interface.new("vlan7")
    br24 = Interface.new("br24")
    br7 = Interface.new("br7")
    d1 = Interface.new("d1")
    d2 = Interface.new("d2")

    eth0.children.push bond0
    eth1.children.push bond0
    bond0.children.push br0
    bond0.children.push vlan24
    bond0.children.push vlan7
    vlan24.children.push br24
    vlan7.children.push br7
    br0.children.push d0
    br24.children.push d0

    br24.children.push d1
    br7.children.push d1

    br24.children.push d2
    br7.children.push d2

    eth2 = Interface.new("eth2")
    vlan2 = Interface.new("vlan2")
    eth2.children.push vlan2

    eth3 = Interface.new("eth3")

    host.interfaces = host_interfaces [
      eth0, eth1, bond0, br0, d0, d2, vlan2, eth3,
      vlan24, vlan7, br24, br7, d1, eth2
    ]
    host
  end

  def invalid_graph
    host = valid_graph
    host.interfaces['br24'].children.push host.interfaces['bond0']
    host
  end

  def xx_test_dump_valid
    graph = Construqt::Graph.build_from_host(valid_graph)
    graph.dump
  end
  def test_dump_invalid
    graph = Construqt::Graph.build_from_host(invalid_graph)
    assert(!graph, "should be nil")
  end

  def test_flat_valid
    graph = Construqt::Graph.build_from_host(valid_graph)
    flat = graph.flat
    assert_equal(["eth0", "eth1", "bond0", "br0", "vlan24", "br24",
     "d0", "vlan7", "br7", "d1", "d2"], flat[0].map{|i| i.ident})
    assert_equal(['eth3'], flat[1].map{|i| i.ident})
    assert_equal(["eth2", "vlan2"], flat[2].map{|i| i.ident})
  end

  def test_nested_bridge_vlan
    host = Host.new("root")
    dev0 = Interface.new("dev0")
    vlan1 = Vlan.new("vlan1")
    vlan1.parents.push dev0
    vlan2 = Vlan.new("vlan2")
    vlan2.parents.push dev0

    br0 = Bridge.new("br0")
    br0.children.push dev0

    br1 = Bridge.new("br1")
    br1.children.push vlan1

    br2 = Bridge.new("br2")
    br2.children.push vlan2

    host.interfaces = host_interfaces [br0,vlan1,br1,br2,vlan2,dev0]
    ret = Construqt::Graph.build_from_host(host)
    binding.pry
    ret.dump
    flat = ret.flat
    assert_equal(ret.map{|i|i.ident}, ["root", "br1", "dev1", "br0", "dev0"])
  end


end
