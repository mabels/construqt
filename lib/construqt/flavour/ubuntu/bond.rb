module Construqt
  module Flavour
    module Ubuntu
      class Bond < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, bond)
          bond_delegate = bond.delegate
          bond_delegate.interfaces.each do |i|
            host.result.etc_network_interfaces.get(i).lines.add("bond-master #{bond_delegate.name}")
          end

          mac_address = bond_delegate.mac_address || Construqt::Util.generate_mac_address_from_name("#{host.name} #{bond_delegate.name}")
          host.result.etc_network_interfaces.get(bond_delegate).lines.add(<<BOND)
pre-up ip link set dev #{bond_delegate.name} mtu #{bond_delegate.mtu} address #{mac_address}
bond-mode #{bond_delegate.mode||'active-backup'}
bond-miimon 100
bond-lacp-rate 1
bond-slaves none
BOND
          Device.build_config(host, bond)
        end
      end
    end
  end
end
