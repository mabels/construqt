
module Construct
  class Templates
    def initialize(region)
      @region = region
      @templates = {}
    end

    class Template < OpenStruct
      def initialize(cfg)
        super(cfg)
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
