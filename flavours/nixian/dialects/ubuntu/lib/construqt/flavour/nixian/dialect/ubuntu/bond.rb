require_relative 'base_device'
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Bond #< OpenStruct
            include BaseDevice
            include Construqt::Cables::Plugin::Single
            def initialize(cfg)
              base_device(cfg)
            end

            def build_config(host, bond)
#echo +bond0 > /sys/class/net/bonding_masters
#echo +enp9s0f0 > /sys/class/net/bond0/bonding/slaves
#echo +enp9s0f1 > /sys/class/net/bond0/bonding/slaves
#echo -enp9s0f1 > /sys/class/net/bond0/bonding/slaves
#echo -bond0 > /sys/class/net/bonding_masters


              bond_delegate = bond.delegate
              bond_delegate.interfaces.each do |i|
                host.result.etc_network_interfaces.get(i).lines.add("bond-master #{bond_delegate.name}")
              end

              mac_address = bond_delegate.mac_address || Construqt::Util.generate_mac_address_from_name("#{host.name} #{bond_delegate.name}")
              host.result.etc_network_interfaces.get(bond_delegate)
                .lines.add(Construqt::Util.render(binding, "bond_interfaces.erb"))
              Device.build_config(host, bond)
            end
          end
        end
      end
    end
  end
end
