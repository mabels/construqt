require_relative 'ipsecs/user.rb'
require_relative 'ipsecs/ipsec.rb'
module Construqt
  module Ipsecs

    IPSECS = {}
    def self.add_connection(cfg, iname)
      throw "my not found #{cfg.keys.inspect}" unless cfg['my']
      throw "host not found #{cfg.keys.inspect}" unless cfg['host']
      throw "remote not found #{cfg.keys.inspect}" unless cfg['remote']
#      binding.pry if cfg['host'].name.start_with?("na-ct-r0")
      cfg['other'] = nil
      cfg['cfg'] = nil
      cfg['my'].host = cfg['host']
      cfg['my'].name = "#{iname}-#{cfg['host'].name}"
      cfg['interface'] = nil
      cfg['host'].flavour.create_ipsec(cfg)
    end

    def self.connection(name, cfg)
      cfg = {}.merge(cfg)
      cfg['left']['hosts'] = ((cfg['left']['hosts']||[]) + [cfg['left']['host']]).compact
      throw "left need atleast one host" if cfg['left']['hosts'].empty?
      cfg['right']['hosts'] = ((cfg['right']['hosts']||[]) + [cfg['right']['host']]).compact
      throw "right need atleast one host" if cfg['right']['hosts'].empty?

      cfg['lefts'] = []
      cfg['rights'] = []
      cfg['left']['hosts'].each do |host|
        my = cfg['left'].merge('host' => host, 'my' => cfg['left']['my'].clone)
        my.delete('lefts')
        my.delete('rights')
        cfg['lefts'] << add_connection(my, Util.add_gre_prefix(cfg['right']['hosts'].map{|h| h.name}.join('-')))
      end

      cfg['right']['hosts'].each do |host|
        my = cfg['right'].merge('host' => host, 'my' => cfg['right']['my'].clone)
        my.delete('lefts')
        my.delete('rights')
        cfg['rights'] << add_connection(my, Util.add_gre_prefix(cfg['left']['hosts'].map{|h| h.name}.join('-')))
      end

      cfg.delete('left')
      cfg.delete('right')
      cfg['name'] = name
      cfg['transport_family'] ||= Construqt::Addresses::IPV6
      cfg = IPSECS[name] = Ipsec.new(cfg)

      cfg.lefts.each do |left|
        left.other = cfg.rights.first
        left.cfg = cfg
        left.host.add_ipsec(cfg)
        left.interface = left.my.host.region.interfaces.add_gre(left.my.host, left.other.host.name,
                                                                "address" => left.my,
                                                                "firewalls" => left.firewalls,
                                                                "local" => left.my,
                                                                "other" => left.other,
                                                                "remote" => left.remote,
                                                                "ipsec" => cfg
                                                               )
      end

      cfg.rights.each do |right|
        right.other = cfg.lefts.first
        right.cfg = cfg
        right.host.add_ipsec(cfg)
        right.interface = right.my.host.region.interfaces.add_gre(right.my.host, right.other.host.name,
                                                                  "address" => right.my,
                                                                  "firewalls" => right.firewalls,
                                                                  "local" => right.my,
                                                                  "other" => right.other,
                                                                  "remote" => right.remote,
                                                                  "ipsec" => cfg
                                                                 )
      end
      (cfg.rights+cfg.lefts).each do |node|
        node.interface.create_interfaces(node.host, node.interface.name, node.cfg);
      end


      cfg
    end

    def self.build_config(hosts_to_process)
      hosts = {}
      IPSECS.values.each do |ipsec|
        (ipsec.rights+ipsec.lefts).each do |iface|
          unless hosts[iface.host.object_id]
            if hosts_to_process.find { |host| host.object_id == iface.host.object_id }
              hosts[iface.host.object_id] = iface.host
            end
          end
        end
      end

      #binding.pry
      hosts.values.each do |host|
        host.flavour.ipsec.header(host) if host.flavour.ipsec.respond_to?(:header)
      end

      IPSECS.each do |name, ipsec|
        ipsec.build_config(hosts_to_process)
      end
    end
  end
end
