

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

module Construqt
  module Flavour
    module Nixian
      module Services
        def self.register(service)
          [
            BgpStartStopImpl,
            ConntrackDImpl,
            DhcpV4RelayImpl,
            DhcpV6RelayImpl,
            IpsecStartStopImpl,
            RadvdImpl,
            LxcImpl,
            VagrantImpl,
            DockerImpl,
            DnsMasqImpl,
          ].each do |clazz|
            service.add(clazz.new)
          end
        end
      end
    end
  end
end
