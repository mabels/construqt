
module Construct
  module Templates
    @templates = []
    class Template < OpenStruct
      def initialize(cfg)
        super(cfg)
      end
    end
    def self.add(name, cfg)
      ret = Template.new(cfg)
      @templates << ret
      ret
    end
  end
end
