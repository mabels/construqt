module Construqt
  module Flavour
    class Mikrotik
      class Template < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(_host, _iface)
          throw 'template not impl'
        end
      end
    end
  end
end
