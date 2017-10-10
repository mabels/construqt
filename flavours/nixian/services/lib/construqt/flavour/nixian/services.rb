

require_relative 'services/bgp_start_stop'
require_relative 'services/conntrack_d'
require_relative 'services/dhcp_v4_relay'
require_relative 'services/dhcp_v6_relay'
require_relative 'services/ipsec_start_stop'
require_relative 'services/radvd'
require_relative 'services/lxc'
require_relative 'services/vagrant'
require_relative 'services/docker'
require_relative 'services/dns_masq'
require_relative 'services/dhcp_client'
require_relative 'services/ssh'
require_relative 'services/result'
require_relative 'services/up_downer'
require_relative 'services/ipsec_strong_swan'
require_relative 'services/tunnel'
require_relative 'services/ipsec_vpn_strong_swan'
require_relative 'services/ip_tables'
require_relative 'services/ip_proxy_neigh'
require_relative 'services/etc_network_interfaces'
require_relative 'services/etc_network_network_ud'
require_relative 'services/etc_network_application_ud'
require_relative 'services/etc_systemd_netdev'
require_relative 'services/etc_systemd_network'
require_relative 'services/etc_systemd_service'
require_relative 'services/modules_conf'
require_relative 'services/packager'
require_relative 'services/reject_routes'
require_relative 'services/deployer_sh'
require_relative 'services/sysctl_conf'
require_relative 'services/invocation'

module Construqt
  module Flavour
    module Nixian
      module Services

        DIRECTORY = File.dirname(__FILE__)

        def self.register(services_factory)
          [
            BgpStartStop::Factory,
            ConntrackD::Factory,
            DhcpClient::Factory,
            DhcpV4Relay::Factory,
            DhcpV6Relay::Factory,
            IpsecStartStop::Factory,
            Radvd::Factory,
            Lxc::Factory,
            Ssh::Factory,
            UpDowner::Factory,
            Tunnel::Factory,
            IpsecStrongSwan::Factory,
            IpsecVpnStrongSwan::Factory,
            IpTables::Factory,
            IpProxyNeigh::Factory,
            Docker::Factory,
            DnsMasq::Factory,
            Result::Factory,
            EtcNetworkInterfaces::Factory,
            EtcNetworkNetworkUd::Factory,
            EtcNetworkApplicationUd::Factory,
            EtcSystemdNetdev::Factory,
            EtcSystemdNetwork::Factory,
            EtcSystemdService::Factory,
            ModulesConf::Factory,
            RejectRoutes::Factory,
            Packager::Factory,
            DeployerSh::Factory,
            SysCtlConf::Factory,
            Invocation::Factory,
          ].each do |clazz|
            services_factory.add(clazz.new)
          end
        end
      end
    end
  end
end
