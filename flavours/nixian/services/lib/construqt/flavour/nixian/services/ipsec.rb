module Construqt
  module Ipsecs
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

      def build_config(hosts_to_process)
        (self.rights+self.lefts).each do |iface|
          # binding.pry
          iface.build_config(iface.host, iface, nil) if hosts_to_process.find{|host| iface.host.object_id == host.object_id }
        end
      end

      def ident
        self.lefts.first.ident
      end
    end
  end
end
