module Construqt
  module Flavour
    class Ciscian
      class Bond < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def self.header(_path)
          '# this is a generated file do not edit!!!!!'
        end

        def build_config(host, bond)
          host.result.dialect.add_bond(bond)
        end
      end
    end
  end
end
