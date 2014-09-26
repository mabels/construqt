require 'securerandom'
require 'construct/flavour/flavour.rb'
require 'construct/flavour/mikrotik/flavour_mikrotik_ipsec.rb'
require 'construct/flavour/mikrotik/flavour_mikrotik_bgp.rb'
require 'construct/flavour/mikrotik/flavour_mikrotik_result.rb'
require 'construct/flavour/mikrotik/flavour_mikrotik_interface.rb'


module Construct

module Flavour

module Mikrotik

  class Schema

    def initialize
      @required = false
      @key = false
      @noset = false
      @type = nil
      @default = nil
    end

    def type
      @type
    end

    def required
      @required = true
      self
    end
    def required?
      @required
    end

    def key
      @key = true
      self
    end
    def key?
      @key
    end

    def noset
      @noset = true
      self
    end
    def noset?
      @noset
    end

    class Int
      def self.serialize(val)
        throw "only 0-9 are allowed [#{val}]" unless val.to_s.match(/^[0-9]+$/)
        return val.to_i
      end
    end
    def int
      @type = Int
      self
    end

    class String
      def self.serialize(val)
        val = val.strip
        return '""' if val.nil? || val.empty?
        return val.to_s.inspect.gsub('$', '\\$')
      end
    end
    def string
      @type = String
      self
    end

    class Identifier
      def self.serialize(val)
        throw "only a-zA-Z0-9_- are allowed [#{val}]" unless val.match(/^[a-zA-Z0-9\-_]+$/)
        return val.to_s
      end
    end
    def identifier
      @type = Identifier
      self
    end

    class Identifiers
      def self.serialize(val)
        val.split(',').map{|i| Identifier.serialize(i) }.join(',').to_s
      end
    end
    def identifiers
      @type = Identifiers
      self
    end

    class Address
      def self.serialize(val)
        throw "only 0-9:\.\/ are allowed #{val}" unless val.match(/^[a-fA-F0-9:\.\/]+$/)
        return val.to_s
      end
    end
    def address
      @type = Address
      self
    end

    def get_default
      @default
    end

    def default(val)
      @default = val
      self
    end

    def self.default(val)
      Schema.new.default(val)
    end

    def self.int
      Schema.new.int
    end

    def self.string
      Schema.new.string
    end

    def self.identifier
      Schema.new.identifier
    end

    def self.identifiers
      Schema.new.identifiers
    end

    def self.address
      Schema.new.address
    end


    def self.key
      Schema.new.key
    end

    def self.noset
      Schema.new.noset
    end

    def self.required
      Schema.new.required
    end
  end

  def self.name
    'mikrotik'
  end
	Flavour.add(self)		

	module Device
    def self.once(host)
    end
		def self.build_config(host, iface)
      default = {
        "l2mtu" => Schema.int.default(1590),
        "mtu" => Schema.int.default(1500),
        "name" => Schema.identifier.default("dummy"),
        "default-name" => Schema.identifier.required.key.noset
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
        "interface" => Schema.identifier.required,
        "name" => Schema.identifier.key.required,
        "priority" => Schema.int.required,
        "v3-protocol" => Schema.identifier.required,
        "vrid" => Schema.int.required
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
        "mode" => Schema.identifier.default("active-backup"),
        "mtu" => Schema.int.required,
        "name" => Schema.identifier.required.key,
        "slaves" => Schema.identifiers.required,
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
        "interface" => Schema.identifier.required,
        "mtu" => Schema.int.required,
        "name" => Schema.identifier.required.key,
        "vlan-id" => Schema.int.required,
      }
      host.result.render_mikrotik(default, {
        "interface" => iface.interface.name,
        "mtu" => iface.mtu,
        "name" => iface.name,
        "vlan-id" => iface.vlan_id
      }, "interface", "vlan")
		end
	end

	module Bridge
    def self.once(host)
    end
		def self.build_config(host, iface)
      default = {
        "auto-mac" => Schema.identifier.default("yes"),
        "mtu" => Schema.int.required,
        "name" => Schema.identifier.required.key,
      }
      host.result.render_mikrotik(default, {
        "mtu" => iface.mtu,
        "name" => iface.name,
      }, "interface", "bridge")
			iface.interfaces.each do |port|
        host.result.render_mikrotik({
          "bridge" => Schema.identifier.required.key,
          "interface" => Schema.identifier.required
        }, {
          "interface" => port.name,
          "bridge" => iface.name,
        }, "interface", "bridge", "port")
			end
		end
	end

	module Host
    def self.once(host)
      host.result.render_mikrotik_set_direct({ "name"=> Schema.identifier.required.key }, { "name" => host.name }, "system", "identity")
      host.result.add("set [ find name!=ssh && name!=www-ssl ] disabled=yes", nil, "ip", "service")
      host.result.add("set [ find ] address=#{host.id.first_ipv6.first_ipv6}", nil, "ip", "service")
      host.result.add("set [ find name!=admin ] comment=REMOVE", nil, "user")

      host.result.render_mikrotik({
        "name" => Schema.identifier.required.key,
        "enc-algorithms" => Schema.identifier.default("aes-256-cbc"),
        "lifetime" => Schema.identifier.default("1h"),
        "pfs-group"=> Schema.identifier.default("modp1536")
      }, {"name" => "s2b-proposal"}, "ip", "ipsec", "proposal")
      host.result.add("", "default=yes", "ip", "ipsec", "proposal")
      host.result.add("", "template=yes", "ip", "ipsec", "policy")
      host.result.add("", "name=default", "routing", "bgp", "instance")
      host.result.add_remove_pre_condition('comment~"CONSTRUCT\$"', "ip", "address")
      host.result.add_remove_pre_condition('comment~"CONSTRUCT\$"', "ip", "route")
      host.result.add_remove_pre_condition('comment~"CONSTRUCT\$"', "ipv6", "address")
      host.result.add_remove_pre_condition('comment~"CONSTRUCT\$"', "ipv6", "route")
      Users.users.each do |u|
        host.result.add(<<OUT, nil, "user")
{
   :local found [find name=#{u.name.inspect} ]
   :if ($found = "") do={
       add comment=#{u.full_name.inspect} name=#{u.name} password=#{Construct::Hosts::default_password} group=full
   } else={
     set $found comment=#{u.full_name.inspect}
   }
}
OUT
      end
      host.result.add("remove [find comment=REMOVE ]", nil, "user" )
      host.result.add("set [ find name=admin] disable=yes", nil, "user")
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
        "name"=>Schema.identifier.required.key,
        "local-address"=>Schema.address.required,
        "remote-address"=>Schema.address.required,
        "dscp"=>Schema.identifier.default("inherit"),
        "mtu"=>Schema.int.default(1476),
        "l2mtu"=>Scheme.int.default(65535)
      }
      host.result.render_mikrotik(default, cfg, "interface", "gre")
    end
    def self.set_interface_gre6(host, cfg) 
      default = {
        "name"=>Schema.identifier.required.key,
        "local-address"=>Schema.address.required,
        "remote-address"=>Schema.address.required,
        "mtu"=>Schema.int.default(1456),
        "l2mtu"=>Schema.int.default(65535)
      }
      host.result.render_mikrotik(default, cfg, "interface", "gre6")
    end
		def self.build_config(host, iface)
      #puts "iface.name=>#{iface.name}"
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
      "address"=>Schema.address.required,
      "interface"=>Schema.identifier.required,
      "comment" => Schema.string.required.key,
      "advertise"=>Schema.identifier.default("no")
    }
    cfg['comment'] = "#{cfg['interface']}-#{cfg['address']}"
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
