require 'construct/interfaces.rb'
require 'securerandom'
require 'construct/hostid.rb'

module Construct

class Hosts

  def initialize(region)
    @region = region
    @hosts = {}
    @default_pwd = SecureRandom.urlsafe_base64(24)
  end
  def region
    @region
  end
  def commit(hosts = nil)
    (hosts || @hosts.values).each { |h| h.commit }
    Flavour.call_aspects("completed", nil, nil)
  end

  def set_default_password(pwd)
      @default_pwd = pwd
  end
  def default_password
    @default_pwd
  end

  class Host < OpenStruct
    def initialize(cfg)
      super(cfg)
      @users = cfg['users'] || cfg['region'].users
    end
    def users
      @users
    end
    def commit
      clazzes = {}
      self.flavour.pre_clazzes { |key, clazz| clazzes[key] = self.flavour.clazz(key) }
      clazzes.each do |key, clazz| 
        Flavour.call_aspects("#{key}.header", self, nil)
        clazz.header(self)
      end
      Flavour.call_aspects("host.commit", self, nil)
      self.result.commit
      clazzes.each do |key, clazz| 
        Flavour.call_aspects("#{key}.footer", self, nil)
        clazz.footer(self)
      end
    end
  end
  def get_hosts()
    @hosts.values
  end
  def add(name, cfg, &block)
    throw "id is not allowed" if cfg['id']
    throw "configip is not allowed" if cfg['configip']
    cfg['interfaces'] = {}
    cfg['id'] ||=nil
    cfg['configip'] ||=nil

    cfg['name'] = name
    cfg['dns_server'] ||= false
    cfg['result'] =nil
    cfg['shadow'] ||=nil
    cfg['flavour'] = Flavour.find(cfg['flavour'] || 'ubuntu')
    throw "flavour #{cfg['flavour']} for host #{name} not found" unless cfg['flavour']
    cfg['region'] = @region
    throw "Host with the name #{name} exisits" if @hosts[name]
    @hosts[name] = Host.new(cfg)
    @hosts[name].result = @hosts[name].flavour.clazz('result').create(@hosts[name])

    block.call(@hosts[name])
    throw "host attribute id is required" unless @hosts[name].id.kind_of? HostId
    throw "host attribute configip is required" unless @hosts[name].configip.kind_of? HostId
  
    if (@hosts[name].id.first_ipv4! && !@hosts[name].id.first_ipv4!.dhcpv4?) ||
       (@hosts[name].id.first_ipv6! && !@hosts[name].id.first_ipv6!.dhcpv6?)
      adr = nil
      if @hosts[name].id.first_ipv4!
        adr = (adr || region.network.addresses.create).add_ip(@hosts[name].id.first_ipv4.first_ipv4.to_s).set_name(@hosts[name].name)
      end
      if @hosts[name].id.first_ipv6!
        adr = (adr || region.network.addresses.create).add_ip(@hosts[name].id.first_ipv6.first_ipv6.to_s).set_name(@hosts[name].name)
      end
      adr = region.network.addresses.create unless adr
      adr.host = @hosts[name] if adr
    end
		@hosts[name]
	end
	def find(name) 
		ret = @hosts[name]
		throw "host not found #{name}" unless ret
		ret
	end
	def build_config(hosts = nil)
    (hosts || @hosts.values).each do |host|
			host.flavour.clazz('host').build_config(host, nil)	
		end
	end
end
end
