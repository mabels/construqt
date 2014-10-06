require 'construct/flavour/flavour.rb'

module Construct
module Flavour
module DlinkDgs15xx
  def self.name
    'dlink-dgs15xx'
  end
  Construct::Flavour.add(self)		

  def self.root
    OpenStruct.new :right => "0644", :owner => 'root'
  end

  def self.root_600
    OpenStruct.new :right => "0600", :owner => 'root'
  end

  def self.root_755
    OpenStruct.new :right => "0600", :owner => 'root'
  end
	
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
    class ArrayWithRight < Array
      attr_accessor :right
      def initialize(right)
        self.right = right
      end
    end
		def add(clazz, block, right, *path)
			path = File.join(@host.name, *path)
			unless @result[path]
				@result[path] = ArrayWithRight.new(right)
        @result[path] << [clazz.header(path)]
			end
			@result[path] << block+"\n"
		end
		def commit
#      Net::SSH.start( HOST, USER, :password => PASS ) do|ssh| 
			@result.each do |name, block|
        #ssh = "ssh root@#{@host.configip.first_ipv4 || @host.configip.first_ipv6}"
				Util.write_str(block.join("\n"), name)
        #out << " mkdir -p #{File.dirname(name)}"
        #out << "scp #{name} "
        #out << "chown #{block.right.owner} #{name}"
        #out << "chmod #{block.right.right} #{name}"
			end
      #Util.write_str(out.join("\n"), @name, "deployer.sh")
		end
	end
	class Interface < OpenStruct
		def initialize(cfg)
			super(cfg)
		end
		def build_config(host, unused)
			self.clazz.build_config(host, self)
		end
	end
	module Device
		def self.header(path)
			"# this is a generated file do not edit!!!!!"
		end
    def self.add_address(host, iface)
      ret = []
			iface.address.ips.each do |ip|
				ret << "  up ip addr add #{ip.to_string} dev #{iface.name}"
				ret << "  down ip addr del #{ip.to_string} dev #{iface.name}"
			end
			iface.address.routes.each do |route|
				ret << "  up ip route add #{route.dst.to_string} via #{route.via.to_s}"
				ret << "  down ip route del #{route.dst.to_string} via #{route.via.to_s}"
			end
      ret << "  up iptables -t raw -A PREROUTING -i #{iface.name} -j NOTRACK"
      ret << "  up iptables -t raw -A OUTPUT -o #{iface.name} -j NOTRACK"
      ret << "  down iptables -t raw -D PREROUTING -i #{iface.name} -j NOTRACK"
      ret << "  down iptables -t raw -D OUTPUT -o #{iface.name} -j NOTRACK"
      ret << "  up ip6tables -t raw -A PREROUTING -i #{iface.name} -j NOTRACK"
      ret << "  up ip6tables -t raw -A OUTPUT -o #{iface.name} -j NOTRACK"
      ret << "  down ip6tables -t raw -D PREROUTING -i #{iface.name} -j NOTRACK"
      ret << "  down ip6tables -t raw -D OUTPUT -o #{iface.name} -j NOTRACK"
      ret
    end
		def self.build_config(host, iface)
			ret = ["auto #{iface.name}", "iface #{iface.name} inet manual"]
			ret << "  up ip link set mtu #{iface.mtu} dev #{iface.name} up"
      ret << "  down ip link set dev #{iface.name} down"
      ret += add_address(host, iface) unless iface.address.nil? || iface.address.ips.empty?
			host.result.add(self, ret.join("\n"), Ubuntu.root, "etc", "network", "interfaces")
		end
	end
	module Vrrp
		def self.header(path)
			"# this is a generated file do not edit!!!!!"
		end
		def self.build_config(host, iface)
			"# this is a generated file do not edit!!!!!"
		end
	end
	module Bond
		def self.build_config(host, iface)
			throw "not implemented bond on ubuntu"
		end
	end
	module Vlan
		def self.build_config(host, iface)
      vlan = iface.name.split('.')
      throw "vlan name not valid if.# => #{iface.name}" if vlan.length != 2 || 
                                                        !vlan.first.match(/^[0-9a-zA-Z]+$/) || 
                                                        !vlan.last.match(/^[0-9]+/) ||
                                                        !(1 <= vlan.last.to_i && vlan.last.to_i < 4096)
		  Device.build_config(host, iface)
		end
	end
	module Bridge
		def self.build_config(host, iface)
			throw "not implemented bridge on ubuntu"
		end
	end
	module Host
		def self.header(path)
			"# this is a generated file do not edit!!!!!"
		end
		def self.build_config(host, unused)
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
		throw "class not found #{name}" unless ret
		ret
	end
	def self.create_interface(name, cfg)
		cfg['name'] = name
		Interface.new(cfg)
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
