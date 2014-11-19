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
  def set_default_password(pwd)
      @default_pwd = pwd
  end
  def default_password
    @default_pwd
  end

  def get_hosts()
    @hosts.values
  end
  def del(name)
    host = @hosts[name]
    return nil unless host
    @hosts.delete(name)
    host
  end
  def add(name, cfg, &block)
#binding.pry
    throw "id is not allowed" if cfg['id']
    throw "configip is not allowed" if cfg['configip']
    throw "Host with the name #{name} exisits" if @hosts[name]
    cfg['interfaces'] = {}
    cfg['id'] ||=nil
    cfg['configip'] ||=nil

    cfg['name'] = name
    cfg['dns_server'] ||= false
    cfg['result'] = nil
    cfg['shadow'] ||= nil
    cfg['flavour'] = Flavour.find(cfg['flavour'] || 'ubuntu')
#		cfg['clazz'] = cfg['flavour'].clazz("host")
    throw "flavour #{cfg['flavour']} for host #{name} not found" unless cfg['flavour']
    cfg['region'] = @region
    host = cfg['flavour'].create_host(name, cfg)
    block.call(host)
    throw "host attribute id is required" unless host.id.kind_of? HostId
    throw "host attribute configip is required" unless host.configip.kind_of? HostId
  
    if (host.id.first_ipv4! && !host.id.first_ipv4!.dhcpv4?) ||
       (host.id.first_ipv6! && !host.id.first_ipv6!.dhcpv6?)
      adr = nil
      if host.id.first_ipv4!
        adr = (adr || region.network.addresses.create).add_ip(host.id.first_ipv4.first_ipv4.to_s).set_name(host.name)
      end
      if host.id.first_ipv6!
        adr = (adr || region.network.addresses.create).add_ip(host.id.first_ipv6.first_ipv6.to_s).set_name(host.name)
      end
      adr = region.network.addresses.create unless adr
      adr.host = host if adr
    end
		@hosts[name] = host
	end
	def find(name) 
		ret = @hosts[name]
		throw "host not found #{name}" unless ret
		ret
	end
	def build_config(hosts = nil)
    (hosts || @hosts.values).each do |host|
      host.build_config(host, nil)	
		end
	end
  def commit(hosts = nil)
    (hosts || @hosts.values).each { |h| h.commit }
    Flavour.call_aspects("completed", nil, nil)
  end

end
end
