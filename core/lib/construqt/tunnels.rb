require_relative 'tunnels/tunnel.rb'
require_relative 'tunnels/endpoint.rb'
require_relative 'tunnels/endpoint_address.rb'

module Construqt
  module Tunnels

    TUNNELS = {}
    def self.add_endpoint(cfg, iname)
      # cfg['host'].flavour.create_ipsec(cfg)
      Endpoint.new(cfg, iname)
    end

    def self.connection(name, cfg)
      cfg = {}.merge(cfg)
      cfg['left']['hosts'] = ((cfg['left']['hosts']||[]) + [cfg['left']['host']]).compact
      throw "left need atleast one host" if cfg['left']['hosts'].empty?
      cfg['right']['hosts'] = ((cfg['right']['hosts']||[]) + [cfg['right']['host']]).compact
      throw "right need atleast one host" if cfg['right']['hosts'].empty?

      cfg['lefts'] = []
      cfg['rights'] = []
      #cfg['left'].each do |ep_cfg|
        #my = cfg['left'].merge('host' => host, 'my' => cfg['left']['my'].clone)
        #my.delete('lefts')
        #my.delete('rights')
      cfg['lefts'] << add_endpoint(cfg['left'], Util.add_gre_prefix(cfg['right']['hosts'].map{|h| h.name}.join('-')))
      #end

      #cfg['right']['hosts'].each do |ep_cfg|
        #my = cfg['right'].merge('host' => host, 'my' => cfg['right']['my'].clone)
        #my.delete('lefts')
        #my.delete('rights')
        cfg['rights'] << add_endpoint(cfg['right'], Util.add_gre_prefix(cfg['left']['hosts'].map{|h| h.name}.join('-')))
      #end

      cfg.delete('left')
      cfg.delete('right')

      cfg['name'] = name
      cfg['transport_family'] ||= Construqt::Addresses::IPV6
      throw "tunnel with this name exists" if TUNNELS[name]
      tunnel = TUNNELS[name] = Tunnel.new(cfg)

      tunnel.lefts.each do |left|
        left.remote = tunnel.right
        left.tunnel = tunnel
        left.host.add_tunnel(tunnel)
        # left.interface = left.host.region.interfaces.add_gre(left.host, left.remote.host.name,
        #                                                         "address" => left.address,
        #                                                         "firewalls" => left.firewalls,
        #                                                         "local" => left.address,
        #                                                         "other" => left.remote.address,
        #                                                         "remote" => left.remote,
        #                                                         "endpoint" => left,
        #                                                         "tunnel" => tunnel
        #                                                        )
      end

      tunnel.rights.each do |right|
        right.remote = tunnel.left
        right.tunnel = tunnel
        right.host.add_tunnel(tunnel)
        # right.interface = right.host.region.interfaces.add_gre(right.host, right.remote.host.name,
        #                                                           "address" => right.address,
        #                                                           "firewalls" => right.firewalls,
        #                                                           "local" => right.address,
        #                                                           "other" => right.remote.address,
        #                                                           "remote" => right.remote,
        #                                                           "endpoint" => right,
        #                                                           "tunnel" => tunnel
        #                                                          )
      end
      (tunnel.rights+tunnel.lefts).each do |node|
        node.create_interfaces #.host, node.interface.name, node.tunnel);
      end
      tunnel
    end

    def self.build_config(hosts_to_process)
      hosts = {}
      TUNNELS.values.each do |tunnel|
        (tunnel.rights+tunnel.lefts).each do |iface|
          unless hosts[iface.host.object_id]
            if hosts_to_process.find { |host| host.object_id == iface.host.object_id }
              hosts[iface.host.object_id] = iface.host
            end
          end
        end
      end
      #binding.pry
      #hosts.values.each do |host|
      #  host.flavour.ipsec.header(host) if host.flavour.ipsec.respond_to?(:header)
      #end
      TUNNELS.each do |name, tunnel|
        tunnel.build_config(hosts_to_process)
      end
    end
  end
end
