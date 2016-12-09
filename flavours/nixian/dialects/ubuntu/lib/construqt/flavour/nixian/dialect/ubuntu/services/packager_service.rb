
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Services
            module PackagerService
              def self.create
                binding.pry
                cps = Packages::Builder.new
                cp = Construqt::Resources::Component
                cps.register(cp::UNREF).add('language-pack-en').add('language-pack-de')
                  .add('git').add('aptitude').add('traceroute')
                  .add('tcpdump').add('strace').add('lsof')
                  .add('ifstat').add('mtr-tiny').add('openssl')
                cps.register(Construqt::Flavour::Delegate::DeviceDelegate)
                cps.register(Construqt::Flavour::Nixian::Dialect::Ubuntu::Wlan)
                cps.register(Construqt::Flavour::Nixian::Dialect::Ubuntu::Systemd)
                cps.register(Construqt::Flavour::Nixian::Dialect::Ubuntu::Bond).add('ifenslave')
                cps.register(Construqt::Flavour::Delegate::VlanDelegate).add('vlan')
                cps.register(Construqt::Flavour::Delegate::TunnelDelegate)
                cps.register(Construqt::Flavour::Nixian::Dialect::Ubuntu::Gre)
                cps.register(Construqt::Flavour::Delegate::GreDelegate)
                cps.register(Construqt::Flavour::Delegate::OpvnDelegate).add('openvpn')
                cps.register(Construqt::Flavour::Delegate::BridgeDelegate).add('bridge-utils')
                cps.register(cp::NTP).add('ntpd')
                cps.register(cp::USB_MODESWITCH).add('usb-modeswitch').add('usb-modeswitch-data')
                cps.register(cp::VRRP).add('keepalived')
                cps.register(cp::FW4).add('iptables').add('ulogd2')
                cps.register(cp::FW6).add('iptables').add('ulogd2')
                [
                  cps.register(Construqt::Flavour::Delegate::IpsecVpnDelegate),
                  cps.register(Construqt::Flavour::Delegate::IpsecDelegate),
                  cps.register(cp::IPSEC)].each do |reg|
                  reg.add('strongswan')
                    .add('strongswan-plugin-eap-mschapv2')
                    .add('strongswan-plugin-xauth-eap')
                end
                cps.register(cp::SSH).add('openssh-server')
                cps.register(cp::BGP).add('bird')
                cps.register(cp::OPENVPN).add('openvpn')
                cps.register(cp::DNS).add('bind9')
                cps.register(cp::RADVD).add('radvd')
                cps.register(cp::DNSMASQ).add('dnsmasq').cmd('update-rc.d dnsmasq disable')
                cps.register(cp::CONNTRACKD).add('conntrackd').add('conntrack')
                cps.register(cp::LXC).add('lxc').add('ruby').add('rubygems-integration')
                cps.register(cp::DOCKER).add('docker.io')
                  .cmd('[ "$(gem list -i linux-lxc)" = "true" ] || gem install linux-lxc --no-ri --no-rdoc')
                cps.register(cp::DHCPRELAY).add('wide-dhcpv6-relay').add('dhcp-helper')
                cps.register(cp::WIRELESS).both('crda').both('iw').mother('linux-firmware')
                  .add('wireless-regdb').add('wpasupplicant')
                cps
              end
            end
          end
        end
      end
    end
  end
end
