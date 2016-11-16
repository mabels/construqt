# require_relative 'hosts/docker.rb'
# require_relative 'hosts/lxc.rb'
# require_relative 'hosts/vagrant.rb'
module Construqt

  class Hosts

  	attr_reader :region
    def initialize(region)
      @region = region
      @hosts = {}
      @graphs = {}
      @default_pwd = SecureRandom.urlsafe_base64(24)
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

    def add(host_name, cfg, &block)
      (host_name, host) = Construqt::Tags.add("#{host_name}##{host_name}") { |name| add_internal(name, cfg) { |h| block.call(h) } }
      host
    end

    class HostInterfaces < Hash
      def bind_host(host)
        @host = host
      end
      def find_by_name(name)
        self[name] || throw("Interface with name [#{name}] not found on host [#{@host.name}]")
      end
      def find_by_name!(name)
        self[name]
      end
    end

    def add_internal(name, cfg, &block)
      #binding.pry
      throw "id is not allowed" if cfg['id']
      throw "configip is not allowed" if cfg['configip']
      throw "Host with the name [#{name}] exists" if @hosts[name]
      cfg['interfaces'] = HostInterfaces.new
      cfg['id'] ||=nil
      cfg['configip'] ||=nil

      cfg['name'] = name
      cfg['dns_server'] ||= false
      cfg['result'] = nil
      cfg['shadow'] ||= nil
      flavour = cfg['flavour'] = @region.flavour_factory.produce(cfg)
      #		cfg['clazz'] = cfg['flavour'].clazz("host")
      throw "flavour #{cfg['flavour']} for host #{name} not found" unless cfg['flavour']
      cfg['services'] = flavour.add_host_services(cfg['services'])
      cfg['region'] = @region
      host = cfg['flavour'].create_host(name, cfg)
      block.call(host)
      host.interfaces.bind_host(host)
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
      (host.services + host.interfaces.values.map do |i|
        binding.pry unless i
        i.services
      end).flatten.each do |srv|
      #host.region.services.services.values.each do |srv|
        if srv.respond_to?(:completed_host)
          srv.completed_host(host)
        end
      end
      host
    end

    def find!(name)
      @hosts[name]
    end

    def find(name)
      ret = @hosts[name]
      throw "host not found #{name}" unless ret
      ret
    end

    def host_graph(hosts = @hosts.values)
      id = @hosts.values.map{|h| h.ident }.sort.join(":")
      unless @graphs[id]
        # binding.pry
        @graphs[id] = Graph.build_host_graph_from_hosts(hosts)
      end
      @graphs[id]
    end

    def build_config(hosts = nil)
      #(hosts || @hosts.values).each do |host|
      #  host.build_config(host, nil)
      #end
      host_graph(hosts).flat.flatten.each do |hnode|
        # binding.pry
        hnode.ref.build_config(hnode.ref, hnode.ref, hnode)
      end
    end

    def commit(hosts = nil)
      regions = {}
      host_graph(hosts || @hosts.values).flat.each do |hnodes|
        hnodes.reverse.each do |hnode|
          next unless hnode.ref.region
          hnode.ref.commit
          regions[hnode.ref.region.object_id] = hnode.ref.region
        end
      end
      regions.values.each do |region|
        region.flavour_factory.call_aspects("completed", region, nil)
      end
    end
  end
end
