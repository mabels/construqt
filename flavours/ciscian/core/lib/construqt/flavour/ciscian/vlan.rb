module Construqt
  module Flavour
    class Ciscian
      class Vlan < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def self.header(_path)
          '# this is a generated file do not edit!!!!!'
        end

        def build_config(host, device)
          host.flavour.dialect.add_vlan(device)
        end
      end
    end
  end
end
