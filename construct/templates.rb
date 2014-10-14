
module Construct
  module Templates
    @templates = {}
    class Template < OpenStruct
      def initialize(cfg)
        super(cfg)
      end
    end
    def self.find(name)
      ret = @templates[name]
      throw "template with name #{name} not found" unless @templates[name]
      ret
    end
    def self.add(name, cfg)
      throw "template with name #{name} exists" if @templates[name]
      cfg['name'] = name
      ret = Template.new(cfg)
      @templates[name] = ret
      ret
    end
  end
end
