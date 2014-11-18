require 'construct/flavour/flavour.rb'

module Construct
module Flavour
module DlinkDgs15xx
  def self.name
    'dlink-dgs15xx'
  end
  Construct::Flavour.add(self)		

# interface ethernet1/0/3
#  description na-l3
#   flowcontrol off
#    max-rcv-frame-size 9216
#     no speed auto-downgrade
#      snmp trap link-status
#       end
  #
#
#
  #
# configure terminal
# vlan 666,901,1300,1700,1703,1718-1720,1724-1725,1802-1803
# exit
# vlan 666
# name tra-l3-r0102-v4
# exit
# vlan 901
# name na-l3-intern
# exit
# 
# configure terminal
# interface ethernet 1/0/3
# switchport mode trunk
# switchport trunk native vlan 901
# switchport trunk allowed vlan 901,1802-1803
# end
# interface port-channel 12
# switchport mode trunk
# switchport trunk native vlan 666
# switchport trunk allowed vlan 1-1299,1301-4094
# end
# 
# configure terminal
#  ip ssh server
#   ssh user root authentication-method password
# end
# 
# configure terminal
# ip telnet server
# ip telnet service-port 23
# end
# 
# configure terminal
# no interface vlan 1
# interface vlan 1300
# ipv6 enable
# ipv6 address FD00:BACC:B0EE:13::12:1/64
# exit
# end
# 
# configure terminal
# no snmp-server
# no snmp-server enable traps
# snmp-server name sw12-1
# snmp-server location L3-HAM
# snmp-server contact meno.abels@sinnerschrader.com
# exit
# 
# configure terminal
# clock timezone + 0  0
# no clock summer-time
# sntp interval 720
# no sntp enable
# exit
# 


#configure terminal
#spanning-tree mode mstp
#spanning-tree mst configuration
#instance 16 vlans 1300
#exit
#end
#configure terminal
  #spanning-tree guard root
  #spanning-tree tcnfilter
#interface ethernet 1/0/1
#spanning-tree mst hello-time 2
#end

	class Result
		def initialize(host)
			@host = host
			@result = {}
		end
    def host
      @host
    end
		def empty?(name)
			not @result[name]
		end
		def add(block, clazz)
			unless @result[clazz]
        @result[clazz] = []
			end
			@result[clazz] << block+"\n"
		end
		def commit
#      Net::SSH.start( HOST, USER, :password => PASS ) do|ssh| 
			@result.each do |clazz, block|
        #ssh = "ssh root@#{@host.configip.first_ipv4 || @host.configip.first_ipv6}"
        Util.write_str(block.join("\n"), File.join(@host.name, "#{clazz}.cfg"))
        #out << " mkdir -p #{File.dirname(name)}"
        #out << "scp #{name} "
        #out << "chown #{block.right.owner} #{name}"
        #out << "chmod #{block.right.right} #{name}"
			end
      #Util.write_str(out.join("\n"), @name, "deployer.sh")
		end
	end
#	class Interface < OpenStruct
#		def initialize(cfg)
#			super(cfg)
#		end
#		def build_config(host, my)
#			self.clazz.build_config(host, my||self)
#		end
#	end
	class Device < OpenStruct
		def initialize(cfg)
			super(cfg)
		end

		def self.header(path)
			"# this is a generated file do not edit!!!!!"
		end
    def self.untagged(template)
      return "" if template.nil? 
      return "" if template.vlans.nil?
      untagged = template.vlans.select{|i| i.untagged? }
      throw "multiple untagged not allowed" if untagged.length > 1
      if untagged.length == 1
        "switchport trunk native vlan #{untagged.first.vlan_id}"
      else
        ""
      end
    end

    def self.tagged(template)
      return "" if template.nil? 
      return "" if template.vlans.nil?
      range = []
      vlan_ids = template.vlans.select{|i| i.tagged? }.map{|i| i.vlan_id}.sort{|a,b| a<=>b }
      vlan_ids.each_with_index do |vlan_id, idx|
#        binding.pry
        if idx == 0
          range << [vlan_id, vlan_id]
        elsif range.last.last == vlan_id-1 # last pushed range last vlan_id see line before
          range.last[1] = vlan_id 
        else 
          range << [vlan_id, vlan_id]
        end
      end
      if range.length
        range_str = range.map{|i| i.first == i.last ? i.first.to_s : "#{i.first}-#{i.last}" }.join(',')
        "switchport trunk allowed vlan #{range_str}"
      else
        ""
      end
    end

    def build_config(host, iface)
      self.class.build_config(host, iface)
    end

    def self.build_config(host, iface)
        host.result.add(<<DEVICE, "device") 
interface #{iface.name}
   flowcontrol off
   max-rcv-frame-size #{iface.delegate.mtu || 9126}
   snmp trap link-status
   switchport mode trunk
   #{untagged(iface.delegate.template)}
   #{tagged(iface.delegate.template)}
end
DEVICE
		end
	end
	class Vrrp < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
		def self.header(path)
			"# this is a generated file do not edit!!!!!"
		end
		def self.build_config(host, iface)
			"# this is a generated file do not edit!!!!!"
		end
	end
	class Bond < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
    def self.header(path)
    end
		def build_config(host, iface)
      throw "need template" unless iface.template
      throw "need intefaces" unless iface.interfaces
      iface.interfaces.each do |i|
        host.result.add(<<BOND, "bond") 
interface #{iface.name}
channel-group #{i.name} mode active
end
BOND
      end
		  Device.build_config(host, iface)
		end
	end
	class Vlan < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
		def build_config(host, iface)
      vlan = iface.name.split('.')
      throw "vlan name not valid if.# => #{iface.name}" if vlan.length != 2 || 
                                                        !vlan.first.match(/^[0-9a-zA-Z]+$/) || 
                                                        !vlan.last.match(/^[0-9]+/) ||
                                                        !(1 <= vlan.last.to_i && vlan.last.to_i < 4096)
		  Device.build_config(host, iface)
		end
	end
	class Bridge
    def initialize(cfg)
      super(cfg)
    end
		def build_config(host, iface)
			throw "not implemented bridge on ubuntu"
		end
	end
	class Host < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
		def self.header(path)
			"# this is a generated file do not edit!!!!!"
		end
		def build_config(host, unused)
      host.interfaces.values.each do |interface|
        #puts "interface=>#{host.name} #{interface.name}"
      end
		end
	end
  
	module Gre
		def self.header(path)
			"# this is a generated file do not edit!!!!!"
		end
		def self.build_config(host, iface)
			throw "not implemented bridge on ubuntu"
    end
	end

	module Opvn
		def self.header(path)
			"# this is a generated file do not edit!!!!!"
		end
		def self.build_config(host, iface)
			throw "not implemented bridge on ubuntu"
    end
	end

  module Template
  end

	def self.clazz(name)
		ret = {
			"opvn" => Opvn, 
			"gre" => Gre, 
			"host" => Host, 
			"device"=> Device, 
			"vrrp" => Vrrp, 
			"bridge" => Bridge,
			"template" => Template,
			"bond" => Bond, 
			"vlan" => Vlan,
			"result" => Result
		       }[name]
    #binding.pry if name == "device"
		throw "class not found #{name}" unless ret
		ret
	end

  def self.create_host(name, cfg)
    cfg['name'] = name
    cfg['result'] = nil
    host = Host.new(cfg)
    host.result = Result.new(host)
    host
  end

	def self.create_interface(name, cfg)
    cfg['name'] = name
    clazz(cfg['clazz']).new(cfg)
		#cfg['name'] = name
		#Interface.new(cfg)
	end

	def self.create_bgp(cfg)
			"# this is a generated file do not edit!!!!!"
	end

	def self.create_ipsec(cfg)
			"# this is a generated file do not edit!!!!!"
	end
end
end
end
