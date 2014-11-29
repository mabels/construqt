
module Construqt
  class Templates
    def initialize(region)
      @region = region
      @templates = {}
    end

    class Template < OpenStruct
      def initialize(cfg)
        super(cfg)
      end

      def is_tagged?(vlan_id)
        self.vlans.each do |vlan|
          return vlan.tagged? if vlan.vlan_id == vlan_id
        end

        throw "vlan with id #{vlan_id} not found in template #{self}"
      end
    end

    def find(name)
      ret = @templates[name]
      throw "template with name #{name} not found" unless @templates[name]
      ret
    end

    def add(name, cfg)
      throw "template with name #{name} exists" if @templates[name]
      cfg['name'] = name
      ret = Template.new(cfg)
      @templates[name] = ret
      ret
    end
  end
end
