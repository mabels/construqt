module Construct
  class Interfaces
    def initialize(region)
      @region = region
    end

    def setup_template(iface)
      iface.template.vlans.each do |vlan|
        vname = "vlan.#{vlan.vlan_id}"
        to_add_iface = iface.host.interfaces[vname]
        unless to_add_iface
          to_add_iface = add_vlan(iface.host, vname, vlan.to_h)
        end

        #puts ">>>>>#{iface.name}"
        to_add_iface.interfaces << iface
      end
    end

    def add_device(host, dev_name, cfg)
      throw "Host not found:#{dev_name}" unless host
      throw "Interface is duplicated:#{host.name}:#{dev_name}" if host.interfaces[dev_name]

      cfg['host'] = host
      cfg['mtu'] ||= 1500
      #binding.pry if host && host.name == "ct-iar1-ham"
      #    binding.pry
      cfg['clazz'] ||= "device"
      (dev_name, iface) = Construct::Tags.add(dev_name) { |name| host.flavour.create_interface(name, cfg) }
      #    iface.clazz.attach = iface
      host.interfaces[dev_name] = iface
      host.interfaces[dev_name].address.interface = host.interfaces[dev_name] if host.interfaces[dev_name].address
      setup_template(iface) if iface.template
      host.interfaces[dev_name]
    end

    def add_template(host, name, cfg)
      cfg['clazz'] = "template"
      cfg['host'] = host
      cfg['name'] = name
      self.add_device(host,name, cfg)
    end

    def add_openvpn(host, name, cfg)
      cfg['clazz'] = "opvn"
      cfg['ipv6'] ||= nil
      cfg['ipv4'] ||= nil
      dev = add_device(host, name, cfg)
      dev.address.interface = host.interfaces[name] if dev.address
      dev.network.name = "#{name}-#{host.name}"
      dev
    end

    def add_gre(host, name, cfg)
      throw "we need an address on this cfg #{cfg.inspect}" unless cfg['address']
      cfg['clazz'] = "gre"
      cfg['local'] ||= nil
      cfg['remote'] ||= nil
      dev = add_device(host, name, cfg)
      dev.address.interface = host.interfaces[name] if dev.address
      dev
    end

    def add_vlan(host, name, cfg)
      cfg = cfg.clone
      interfaces = cfg['interfaces'] || []
      interfaces << cfg['interface'] if cfg['interface']
      cfg.delete('interface')
      cfg['interfaces'] = interfaces
      #    throw "we need an interface #{cfg['interfaces']}" if cfg['interfaces'].empty?
      cfg['clazz'] = "vlan"
      dev = add_device(host, name, cfg)
      dev.address.interface = host.interfaces[name] if dev.address
      dev
    end

    def add_bond(host, name, cfg)
      cfg['interfaces'].each do |interface|
        throw "interface not one same host:#{interface.host.name}:#{host.name}" unless host.name == interface.host.name
      end

      cfg['clazz'] = "bond"
      dev = add_device(host, name, cfg)
      dev.address.interface = host.interfaces[name] if dev.address
      dev
    end

    def add_vrrp(name, cfg)
      nets = {}
      cfg['address'].ips.each do |adr|
        throw "only host ip's are allowed #{adr.to_s}" if adr.ipv4? && adr.prefix != 32
        throw "only host ip's are allowed #{adr.to_s}" if adr.ipv6? && adr.prefix != 128
        nets[adr.network.to_s] = true
      end

      cfg['interfaces'].each do |interface|
        throw "interface need priority #{interface}" unless interface.priority
        throw "interface not found:#{name}" unless interface
        cfg['clazz'] = "vrrp"
        cfg['interface'] = interface
        throw "vrrp interface does not have within the same network" if nets.length == interface.address.ips.select { |adr| nets[adr.network.to_s] }.length
        dev = add_device(interface.host, name, cfg)
        dev.address.interface = nil
        dev.address.host = nil
        dev.address.name = name
      end
    end

    def add_bridge(host, name, cfg)
      #cfg['interfaces'] = []
      cfg['interfaces'].each do |interface|
        throw "interface not one same host:#{interface.host.name}:#{host.name}" unless host.name == interface.host.name
      end

      cfg['clazz'] = "bridge"
      dev = add_device(host, name, cfg)
      dev.address.interface = host.interfaces[name] if dev.address
      dev
    end

    def find(host_or_name, iface_name)
      if host_or_name.kind_of?(String)
        host = @region.hosts.find(host_or_name)
        throw "host not found #{host_or_name}" unless host
      else
        host = host_or_name
      end

      iface = host.interfaces[iface_name]
      throw "interface not found for #{iface_name}:#{host.name}" unless iface
      iface
    end

    def build_config(hosts = nil)
      (hosts||Hosts.get_hosts).each do |host|
        #binding.pry
        by_clazz = {}
        host.interfaces.values.each do |interface|
          #throw "class less interface #{interface.inspect}" unless interface.clazz
          #throw "no clazz defined in interface #{interface.clazz}" unless interface.clazz.name
          name = interface.clazz # .name[interface.clazz.name.rindex(':')+1..-1].downcase
          #puts "<<<<<<< #{name}"
          by_clazz[name] ||= []
          by_clazz[name] << interface
        end

        ["host", "device", "vlan", "bond", "bridge", "vrrp", "gre", "bgp", "opvn", "ipsec"].each do |key|
          next unless by_clazz[key]
          by_clazz[key].each do |interface|
            #Construct.logger.debug "Interface:build_config:#{interface.name}:#{interface.class.name}:#{interface.ident}"
            interface.build_config(host, interface)
          end
        end
      end
    end
  end
end
