module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module BaseDevice
            attr_accessor :delegate
            attr_reader :host, :name, :address, :template, :plug_in
            attr_reader :services, :clazz, :mtu, :flavour, :proxy_neigh
            attr_reader :mac_address, :vagrant, :firewalls, :network
            attr_reader :services, :description, :priority
            def base_device(cfg)
              @cfg = cfg
              @name = cfg['name']
              @description = cfg['description']
              @host = cfg['host']
              @services = cfg['services']
              @address = cfg['address']
              @template = cfg['template']
              @plug_in = cfg['plug_in']
              @services = cfg['services']
              @clazz = cfg['clazz']
              @mtu = cfg['mtu']
              @flavour = cfg['flavour']
              @proxy_neigh = cfg['proxy_neigh']
              @mac_address = cfg['mac_address']
              # @vagrant = cfg['vagrant']
              @firewalls = cfg['firewalls']
              @network = cfg['network']
              @startup = cfg['startup']
              @priority = cfg['priority']
            end

            def startup?
              @startup
            end

            def inspect
              "#<#{self.class.name}:#{"%x"%object_id} ident=#{self.delegate.ident}>"
            end

          end
        end
      end
    end
  end
end
