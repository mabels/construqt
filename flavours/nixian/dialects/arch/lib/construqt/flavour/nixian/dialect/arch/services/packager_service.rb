
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Arch
          module Services
            module PackagerService
              def self.create
                cps = Packages::Builder.new
                cp = Construqt::Resources::Component
                cps.register(cp::UNREF).add('git').add('traceroute')
                  .add('tcpdump').add('strace').add('lsof')
                  .add('mtr').add('openssl')
                cps.register(Construqt::Flavour::Delegate::DeviceDelegate)
                cps.register(Construqt::Flavour::Nixian::Dialect::Ubuntu::Wlan)
                cps.register(Construqt::Resources::Component::SYSTEMD)
                cps.register(Construqt::Flavour::Nixian::Dialect::Ubuntu::Bond).add('ifenslave')
                cps.register(Construqt::Flavour::Delegate::VlanDelegate).add('vlan')
                cps.register(Construqt::Flavour::Delegate::TunnelDelegate)
                cps.register(Construqt::Flavour::Nixian::Dialect::Ubuntu::Gre)
                cps.register(Construqt::Flavour::Delegate::GreDelegate)
                cps.register(Construqt::Flavour::Delegate::OpvnDelegate).add('openvpn')
                cps.register(Construqt::Flavour::Delegate::BridgeDelegate).add('bridge-utils')
                cps.register(cp::NTP).add('openntpd')
                cps.register(cp::USB_MODESWITCH).add('usb_modeswitch')
                cps.register(cp::VRRP).add('keepalived')
                cps.register(cp::FW4).add('iptables').add('ulogd')
                cps.register(cp::FW6).add('iptables').add('ulogd')
                #[
                #  cps.register(Construqt::Flavour::Delegate::IpsecVpnDelegate),
                #  cps.register(Construqt::Flavour::Delegate::IpsecDelegate),
                #  cps.register(cp::IPSEC)].each do |reg|
                #reg.add('strongswan')
                #  .add('strongswan-plugin-eap-mschapv2')
                #  .add('strongswan-plugin-xauth-eap')
                #end

                cps.register(cp::SSH).add('openssh')
                cps.register(cp::BGP).add('bird').add('bird6')
                cps.register(cp::OPENVPN).add('openvpn')
                cps.register(cp::DNS).add('bind')
                cps.register(cp::RADVD).add('radvd')
                cps.register(cp::DNSMASQ).add('dnsmasq')
                cps.register(cp::CONNTRACKD).add('conntrack-tools')
                cps.register(cp::LXC).add('lxc').add('ruby')
                  .cmd('[ "$(gem list -i linux-lxc)" = "true" ] || gem install linux-lxc --no-ri --no-rdoc')
                cps.register(cp::DOCKER) #.add('docker')
                #cps.register(cp::DHCPRELAY).add('wide-dhcpv6-relay').add('dhcp-helper')
                #cps.register(cp::WIRELESS).both('crda').both('iw').mother('linux-firmware')
                #  .add('wireless-regdb').add('wpasupplicant')
                cps
              end
            end
          end
        end
      end
    end
  end
end
