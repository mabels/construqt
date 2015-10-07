module Construqt
  module Flavour
    module Ubuntu
      class Template < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
        end
      end

    end
  end
end
