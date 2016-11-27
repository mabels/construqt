

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
require_relative 'services/ipsec_vpn_strong_swan'
require_relative 'services/ipsec_vpn_strong_swan'
require_relative 'services/ipsec_vpn_strong_swan'
require_relative 'services/ip_tables'
require_relative 'services/ip_proxy_neigh'

module Construqt
  module Flavour
    module Nixian
      module Services

        DIRECTORY = File.dirname(__FILE__)

        def self.register(services_factory)
          [
            BgpStartStopFactory,
            ConntrackDFactory,
            DhcpClientFactory,
            DhcpV4RelayFactory,
            DhcpV6RelayFactory,
            IpsecStartStopFactory,
            RadvdFactory,
            LxcFactory,
            SshFactory,
            UpDowner::Factory,
            IpsecStrongSwanFactory,
            IpsecVpnStrongSwanFactory,
            IpTablesFactory,
            IpProxyNeighFactory,
            DockerFactory,
            DnsMasqFactory,
            ResultFactory
          ].each do |clazz|
            services_factory.add(clazz.new(services_factory))
          end
        end
      end
    end
  end
end
