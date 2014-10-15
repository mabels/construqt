require 'construct/flavour/flavour.rb'

module Construct
module Flavour
module Unknown
  def self.name
    'unknown'
  end
  Construct::Flavour.add(self)		

	module Device
		def self.header(path)
		end
		def self.build_config(host, iface)
		end
	end
	module Vrrp
		def self.header(path)
		end
		def self.build_config(host, iface)
		end
	end
	module Bond
    def self.header(path)
    end
		def self.build_config(host, iface)
		end
	end
	module Vlan
		def self.build_config(host, iface)
		end
	end
	module Bridge
		def self.build_config(host, iface)
		end
	end
	module Host
		def self.header(path)
		end
		def self.build_config(host, unused)
		end
	end
  
	module Gre
		def self.header(path)
		end
		def self.build_config(host, iface)
    end
	end

	module Opvn
		def self.header(path)
		end
		def self.build_config(host, iface)
    end
	end

  module Template
  end

  class Result
		def initialize(host)
    end
    def commit
    end
  end
	class Interface < OpenStruct
		def initialize(cfg)
      super(cfg)
		end
		def build_config(host, unused)
		end
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

  class Bgp < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
    def build_config(unused, unused1)
    end
  end

	def self.create_bgp(cfg)
    Bgp.new(cfg)
	end

  class Ipsec < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
    def build_config(unused, unused1)
    end
  end

	def self.create_ipsec(cfg)
    Ipsec.new(cfg)
	end
end
end
end
