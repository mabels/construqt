
module Construqt
  module Ipsecs
    class User
      attr_reader :name, :psk
      def initialize(name, psk)
        @name = name
        @psk = psk
      end
    end
    class Ipsec
      attr_reader :rights, :lefts, :transport_family, :password
      attr_reader :name, :keyexchange, :description, :address
      attr_reader :delegate, :tags, :mtu_v4, :mtu_v6, :cipher
      def initialize(cfg)
        @cfg = cfg
        @cipher = @cfg['cipher']
        @rights = @cfg['rights']
        @lefts = @cfg['lefts']
        @transport_family = @cfg['transport_family']
        @password = @cfg['password']
        @name = @cfg['name']
        @keyexchange = @cfg['keyexchange']
        @description = @cfg['description']
        @address = @cfg['address']
        @mtu_v4 = @cfg['mtu_v4']
        @mtu_v6 = @cfg['mtu_v6']
        @delegate = nil
        @tags = nil
      end

      def build_config()
        (self.rights+self.lefts).each do |iface|
          iface.build_config(iface.host, iface)
        end
      end

      def ident
        self.lefts.first.ident
      end
    end

    @ipsecs = {}
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
      cfg = @ipsecs[name] = Ipsec.new(cfg)

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

      cfg
    end

    def self.build_config()
      hosts = {}
      @ipsecs.values.each do |ipsec|
        (ipsec.rights+ipsec.lefts).each do |iface|
          hosts[iface.host.object_id] ||= iface.host
        end
      end

      #binding.pry
      hosts.values.each do |host|
        host.flavour.ipsec.header(host) if host.flavour.ipsec.respond_to?(:header)
      end

      @ipsecs.each do |name, ipsec|
        ipsec.build_config()
      end
    end
  end
end
