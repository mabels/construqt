require 'securerandom'
require 'construct/flavour/flavour.rb'
require 'construct/flavour/mikrotik/flavour_mikrotik_ipsec.rb'
require 'construct/flavour/mikrotik/flavour_mikrotik_bgp.rb'
require 'construct/flavour/mikrotik/flavour_mikrotik_result.rb'
require 'construct/flavour/mikrotik/flavour_mikrotik_interface.rb'


module Construct

module Flavour

module Mikrotik

  def self.name
    'mikrotik'
  end
	Flavour.add(self)		

	module Device
    def self.once(host)
    end
		def self.build_config(host, iface)
      default = {
        "l2mtu" => 1590,
        "mtu" => 1500,
        "name" => "dummy",
        "default-name" => nil
      }
      host.result.render_mikrotik_set_by_key(default, {
        "l2mtu" => iface.mtu,
        "mtu" => iface.mtu,
        "name" => iface.name,
        "default-name" => iface.default_name
      }, "interface")
		end
	end

	module Vrrp
    def self.once(host)
    end
		def self.build_config(host, iface)
      default = {
        "interface" => nil,
        "name" => nil,
        "priority" => nil,
        "v3-protocol" => nil,
        "vrid" => nil
      }
      host.result.render_mikrotik(default, {
        "interface" => iface.interface.name,
        "name" => iface.name,
        "priority" => iface.interface.priority,
        "v3-protocol" => "ipv6",
        "vrid" => iface.vrid
      }, "interface", "vrrp")
		end
	end

	module Bond
    def self.once(host)
    end
		def self.build_config(host, iface)
      default = {
        "mode" => "active-backup",
        "mtu" => nil,
        "name" => nil,
        "slaves" => nil,
      }
      host.result.render_mikrotik(default, {
        "mtu" => iface.mtu,
        "name" => iface.name,
        "slaves" => iface.interfaces.map{|iface| iface.name}.join(',')
      }, "interface", "bonding")
		end
	end

	module Vlan
    def self.once(host)
    end
		def self.build_config(host, iface)
      default = {
        "interface" => nil,
        "mtu" => nil,
        "name" => nil,
        "vlan-id" => nil,
      }
      host.result.render_mikrotik(default, {
        "interface" => iface.interface.name,
        "mtu" => iface.mtu,
        "name" => iface.name,
        "vlan-id" => iface.vlan_id,
      }, "interface", "vlan")
		end
	end

	module Bridge
    def self.once(host)
    end
		def self.build_config(host, iface)
      default = {
        "auto-mac" => "yes",
        "mtu" => nil,
        "name" => nil,
      }
      host.result.render_mikrotik(default, {
        "mtu" => iface.mtu,
        "name" => iface.name,
      }, "interface", "bridge")
			iface.interfaces.each do |port|
        host.result.render_mikrotik({
            "bridge" => nil,
            "interface" => nil
        }, {
          "interface" => port.name,
          "bridge" => iface.name,
        }, "interface", "bridge", "port")
			end
		end
	end

	module Host
    def self.once(host)
      host.result.render_mikrotik_set_direct({ "name"=> nil }, { "name" => host.name }, "system", "identity")
      host.result.add("set [ find name!=ssh && name!=www-ssl ] disabled=yes", nil, "ip", "service")
      host.result.add("set [ find ] address=#{host.id.first_ipv6.first_ipv6}", nil, "ip", "service")
      host.result.add("set [ find name=admin] disable=yes", nil, "user")
      host.result.add("set [ find name!=admin ] comment=REMOVE", nil, "user")
      Users.users.each do |u|
        host.result.add(<<OUT, nil, "user")
{
   :local found [find "name" = #{u.name.inspect} ]
   :if ($found = "") do={
       add comment=#{u.full_name.inspect} name=#{u.name} password=#{Construct::Hosts::default_password} group=full
   } else={
     set $found comment=#{u.full_name.inspect}
   }
}
OUT
      end
      host.result.add("remove [find comment=REMOVE ]", nil, "user" )
    end
		def self.build_config(host)
			ret = ["# host"]
		end
	end
	module Ovpn
    def self.once(host)
    end
		def self.build_config(host, iface)
			throw "ovpn not impl"
		end
	end
	module Gre
    def self.once(host)
    end
    def self.set_interface_gre(host, cfg) 
      default = {
        "name"=>nil,
        "local-address"=>nil,
        "remote-address"=>nil,
        "dscp"=>"inherit",
        "mtu"=>"1476",
        "l2mtu"=>"65535"
      }
      host.result.render_mikrotik(default, cfg, "interface", "gre")
    end
    def self.set_interface_gre6(host, cfg) 
      default = {
        "name"=>nil,
        "local-address"=>nil,
        "remote-address"=>nil,
        "mtu"=>"1456",
        "l2mtu"=>"65535"
      }
      host.result.render_mikrotik(default, cfg, "interface", "gre6")
    end
		def self.build_config(host, iface)
      puts "iface.name=>#{iface.name}"
      #binding.pry
      #iname = Util.clean_if("gre6", "#{iface.name}")
      set_interface_gre6(host, "name"=> iface.name, 
                         "local-address"=>iface.local.to_s,
                         "remote-address"=>iface.remote.to_s)
      #Mikrotik.set_ipv6_address(host, "address"=>iface.address.first_ipv6.to_string, "interface" => iname)
		end
	end
  def self.set_ipv6_address(host, cfg)
    default = {
      "address"=>nil,
      "interface"=>nil,
      "advertise"=>"no"
    }
    host.result.render_mikrotik(default, cfg, "ipv6", "address")
  end
  def self.pre_clazzes(&block)
    self.clazzes.values.each do |clazz|
        block.call(clazz)
    end
  end
  def self.clazzes
		ret = {
			"opvn" => Ovpn, 
			"gre" => Gre, 
			"host" => Host, 
			"device"=> Device, 
			"vrrp" => Vrrp, 
			"bridge" => Bridge,
			"bond" => Bond, 
			"vlan" => Vlan,
			"result" => Result
	  }
  end
	def self.clazz(name)
    ret = self.clazzes[name]
		throw "class not found #{name}" unless ret
		ret
	end
	def self.create_interface(name, cfg)
		cfg['name'] = name
		iface = Interface.new(cfg)
		iface
	end

	def self.create_bgp(cfg)
		Bgp.new(cfg)
	end
	def self.create_ipsec(cfg)
		Ipsec.new(cfg)
	end
end
end
end
