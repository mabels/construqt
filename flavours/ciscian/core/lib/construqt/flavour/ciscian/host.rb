module Construqt
  module Flavour
    class Ciscian
      class Host < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def header(_host)
          '# this is a generated file do not edit!!!!!'
        end

        def footer(_host)
          '# this is a generated file do not edit!!!!!'
        end

        def build_config(host, _unused)
          host.flavour.dialect.add_host(host)
        end
      end
    end
  end
end
