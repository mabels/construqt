require 'logger'

require 'fileutils'
require 'ostruct'

require 'ipaddress.rb'


module Construct

  @logger = Logger.new(STDOUT)
  @logger.level = Logger::DEBUG

  def self.log_level(level)
    @logger.level = level
  end
  if !IPAddress::IPv6.instance_methods.include?(:rev_domains)
    @logger.fatal "you need the right ipaddress version from https://github.com/mabels/ipaddress" 
  end
  if !OpenStruct.instance_methods.include?(:to_h)
    OpenStruct.class_eval do
      def to_h
          @table.dup
      end
    end
    @logger.warn "Your running a patched version of OpenStruct"
  end

  def self.logger
    @logger 
  end



  # ugly but i need the logger during initialization
  require 'construct/util.rb'
  require 'construct/services.rb'
  require 'construct/networks.rb'
  require 'construct/addresses.rb'
  require 'construct/bgps.rb'
  require 'construct/users.rb'
  require 'construct/firewalls.rb'
  require 'construct/flavour/delegates.rb'
  require 'construct/resource.rb'
  require 'construct/hosts.rb'
  require 'construct/interfaces.rb'
  require 'construct/cables.rb'
  require 'construct/ipsecs.rb'
  require 'construct/firewalls.rb'
  require 'construct/templates.rb'
  require 'construct/regions.rb'
  require 'construct/vlans.rb'
  require 'construct/tags.rb'
  require 'construct/flavour/flavour.rb'

  require 'construct/flavour/unknown/flavour_unknown.rb'
  ['construct/flavour/dlink-dgs15xx/flavour_dlink_dgs15xx.rb',
   'construct/flavour/hp-procurve/flavour_hp-procurve.rb',
   'construct/flavour/graphviz/graphviz.rb',
   'construct/flavour/plantuml/plantuml.rb',
   'construct/flavour/mikrotik/flavour_mikrotik.rb',
   'construct/flavour/ubuntu/flavour_ubuntu.rb'].each do |fname|
    begin
      require fname 
    rescue LoadError
      Construct::logger.warn("can not load driver:#{fname}")
    end
  end

  def self.produce(region_or_hosts)
    hosts = false
    hosts = region_or_hosts if region_or_hosts.kind_of?(Array)
    hosts = region_or_hosts.hosts.get_hosts if region_or_hosts.kind_of?(Construct::Regions::Region)
    throw "need a region or hosts list" unless hosts
    Construct::Ipsecs.build_config()
    Construct::Bgps.build_config()
    hosts.inject({}) do |r, host| 
      r[host.region.name] ||= []
      r[host.region.name] << host
      r 
    end.values.each do |hosts|
      hosts.first.region.hosts.build_config(hosts)
      hosts.first.region.interfaces.build_config(hosts)
      hosts.first.region.hosts.commit(hosts)
    end
  end

end
