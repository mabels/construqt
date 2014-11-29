
module Construqt
  class Vlans
    def initialize(region)
      @region = region
      @vlans_id = {}
      @vlans_description = {}
    end

    class Vlan < OpenStruct
      def initialize(cfg)
        super(cfg)
      end

      def tagged?
        @tagged
      end

      def tagged
        @tagged=true
        self
      end

      def untagged?
        !@tagged
      end

      def untagged
        @tagged = false
        self
      end
    end

    def add(vlan, cfg)
      throw "vlan has to be a fixnum #{vlan}" unless vlan.kind_of?(Fixnum)
      throw "vlan need #{vlan} description" unless cfg['description']
      throw "vlan with id #{vlan} exists" if @vlans_id[vlan]
      throw "vlan with description #{vlan} exists" if @vlans_description[cfg['description']]
      cfg['vlan_id'] = vlan
      ret = Vlan.new(cfg)
      @vlans_id[vlan] = ret
      @vlans_description[cfg['description']] = ret
      ret
    end

    def clone(key)
      throw "vlan clone key not found #{key}" unless @vlans_id[key] || @vlans_description[key]
      (@vlans_id[key] || @vlans_description[key]).clone
    end
  end
end
