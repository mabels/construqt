
module Construct
  module Vlans
    @vlans = []
    class Vlan < OpenStruct
      def initialize(cfg)
        super(cfg)
        @tagged = true
        @untagged = false
      end
      def tagged?
        @tagged
      end
      def tagged
        @tagged = true
        self
      end
      def untagged?
        @untagged
      end
      def untagged
        @untagged = true
        self
      end
    end
    def self.add(vlan, description)
      ret = Vlan.new("vlan" => vlan, "description" => description)
      @vlans << ret
      ret
    end
    def self.clone(key)
      ret = @vlans.find{|vlan| vlan.vlan.to_s == key || vlan.description.to_s == key }
      throw "vlan clone key not found #{key}" unless ret
      ret
    end
  end
end
