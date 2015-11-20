module Construqt
  module Flavour
    class Mikrotik
      class Ovpn < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(_host, _iface)
          throw 'ovpn not impl'
        end
      end
    end
  end
end
