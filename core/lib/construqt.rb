require 'logger'

require 'fileutils'
require 'ostruct'

require 'construqt/ipaddress'
require 'digest/sha1'
require 'digest/md5'
require "base64"
require 'securerandom'


module Construqt

  @logger = Logger.new(STDOUT)
  @LOGLEVEL||=Logger::DEBUG
  @logger.level = @LOGLEVEL

  def self.log_level(level)
    @logger.level = level
  end

  #if !IPAddress::IPv6.instance_methods.include?(:rev_domains)
  #  @logger.fatal "you need the right ipaddress version from https://github.com/mabels/ipaddress"
  #end

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
  require_relative 'construqt/util.rb'
  require_relative 'construqt/service_machine.rb'
  require_relative 'construqt/services_factory.rb'
  require_relative 'construqt/registry.rb'
  require_relative 'construqt/registries/ripe.rb'
  require_relative 'construqt/networks.rb'
  require_relative 'construqt/addresses.rb'
  require_relative 'construqt/routing_table.rb'
  require_relative 'construqt/bgps.rb'
  require_relative 'construqt/dhcp.rb'
  require_relative 'construqt/dns.rb'
  require_relative 'construqt/packages.rb'
  require_relative 'construqt/ntp.rb'
  require_relative 'construqt/users.rb'
  require_relative 'construqt/cert_store.rb'
  require_relative 'construqt/firewalls.rb'
  require_relative 'construqt/resource.rb'
  require_relative 'construqt/flavour/delegate.rb'
  require_relative 'construqt/hostid.rb'
  require_relative 'construqt/services.rb'
  require_relative 'construqt/hosts.rb'
  require_relative 'construqt/interfaces.rb'
  require_relative 'construqt/cables.rb'
  require_relative 'construqt/tunnels.rb'
  require_relative 'construqt/ipsecs.rb'
  require_relative 'construqt/firewalls.rb'
  require_relative 'construqt/templates.rb'
  require_relative 'construqt/regions.rb'
  require_relative 'construqt/vlans.rb'
  require_relative 'construqt/tags.rb'
  require_relative 'construqt/graph.rb'
  require_relative 'construqt/flavour/factory.rb'
  require_relative 'construqt/flavour/dialect_factory_base.rb'
  require_relative 'construqt/flavour/node.rb'
  require_relative 'construqt/spanning_tree.rb'

  require_relative 'construqt/services_result.rb'
#  [ 'onstruqt/flavour/unknown/unknown.rb',
#    'construqt/flavour/ciscian/ciscian.rb',
#    'construqt/flavour/plantuml/plantuml.rb',
#    'construqt/flavour/mikrotik/flavour_mikrotik.rb',
#    'construqt/flavour/nixian/nixian.rb',
#    'construqt/flavour/ubuntu/flavour_ubuntu.rb'].each do |fname|
#    begin
#      require_relative fname
#    rescue LoadError
#      Construqt::logger.warn("can not load driver:#{fname}")
#    end
#  end

  def self.produce(region_or_hosts)
    hosts = false
    hosts = region_or_hosts if region_or_hosts.kind_of?(Array)
    hosts = region_or_hosts.hosts.get_hosts if region_or_hosts.kind_of?(Construqt::Regions::Region)
    throw "need a region or hosts list" unless hosts

    service_result = HostsServicesResult.new
    service_result.attach_from_hosts(hosts)
    service_result.fire_construction_order(:start)

    Construqt::Ipsecs.build_config(hosts)
    Construqt::Bgps.build_config(hosts)
    hosts.inject({}) do |r, host|
      if r[host.region.name].nil?
        host.region.registry && host.region.registry.produce
        r[host.region.name] ||= []
      end
      r[host.region.name] << host
      r
    end.values.each do |hosts|

      ghosts = Graph.build_host_graph_from_hosts(hosts).flat
      ohosts = []
      ghosts.each do |fhosts|
        ohosts += fhosts.reverse.map{|i| i.ref }
      end
      hosts.first.region.hosts.build_config(service_result, ohosts)
      hosts.first.region.interfaces.build_config(service_result, ohosts)
      hosts.first.region.hosts.post_interfaces(service_result, ohosts)
      hosts.first.region.hosts.commit(service_result, ohosts)
    end
  end

end
