require 'construct/interfaces.rb'
require 'securerandom'

module Construct
module Hosts
  @hosts = {}
  def self.commit
    @hosts.values.each { |h| h.commit }
    Flavour.call_aspects("completed", nil, nil)
  end

  @default_pwd = SecureRandom.urlsafe_base64(24)
  def self.set_default_password(pwd)
      @default_pwd = pwd
  end
  def self.default_password
    @default_pwd
  end

  class HostId 
      attr_accessor :interfaces
      def self.create(&block) 
        a = HostId.new()
        a.interfaces=[]
        block.call(a)
        return a
      end
      def first_ipv6!
        self.interfaces.each do |i| 
          return i.address if i.address.first_ipv6
        end
        nil
      end
      def first_ipv6
        ret = first_ipv6!
        throw "first_ipv6 failed #{self.interfaces.first.host.name}" unless ret
        ret
      end
      def first_ipv4!
        self.interfaces.each do |i| 
          return i.address if i.address.first_ipv4
        end
        nil
      end
      def first_ipv4
        ret = first_ipv4!
        throw "first_ipv4 failed #{self.interfaces.first.host.name}" unless ret
        ret
      end
  end
  class Host < OpenStruct
    def initialize(cfg)
      super(cfg)
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
  def self.get_hosts()
    @hosts.values
  end
  def self.add(name, cfg, &block)
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
    @hosts[name] = Host.new(cfg)
    @hosts[name].result = @hosts[name].flavour.clazz('result').create(@hosts[name])

    block.call(@hosts[name])
    throw "host attribute id is required" unless @hosts[name].id.kind_of? HostId
    throw "host attribute configip is required" unless @hosts[name].configip.kind_of? HostId
  
#binding.pry
    if (@hosts[name].id.first_ipv4! && !@hosts[name].id.first_ipv4!.dhcpv4?) ||
       (@hosts[name].id.first_ipv6! && !@hosts[name].id.first_ipv6!.dhcpv6?)
      adr = nil
      if @hosts[name].id.first_ipv4!
        adr = (adr || Construct::Addresses).add_ip(@hosts[name].id.first_ipv4.first_ipv4.to_s).set_name(@hosts[name].name)
      end
      if @hosts[name].id.first_ipv6!
        adr = (adr || Construct::Addresses).add_ip(@hosts[name].id.first_ipv6.first_ipv6.to_s).set_name(@hosts[name].name)
      end
      adr = Construct::Addresses::Addresss.new unless adr
      adr.host = @hosts[name] if adr
    end
		@hosts[name]
	end
	def self.find(name) 
		ret = @hosts[name]
		throw "host not found #{name}" unless ret
		ret
	end
	def self.build_config()
		@hosts.each do |name, host|
			host.flavour.clazz('host').build_config(host, nil)	
		end
	end
end
end
