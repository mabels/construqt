module Construqt
  module Flavour
    class Ciscian
      class NotImplemented < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def self.header(_path)
          '# this is a generated file do not edit!!!!!'
        end

        def build_config(_host, iface)
          throw "not implemented on this flavour #{iface.class.name}"
        end
      end
    end
  end
end
