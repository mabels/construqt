require_relative 'updown/device'
require_relative 'updown/bgp'
require_relative 'updown/bridge'
require_relative 'updown/bridge_member'
require_relative 'updown/dhcp_client'
require_relative 'updown/dhcp_v4_relay'
require_relative 'updown/dhcp_v6_relay'
require_relative 'updown/dhcp_v4'
require_relative 'updown/dhcp_v6'
require_relative 'updown/dns_masq'
require_relative 'updown/ip_addr'
require_relative 'updown/ip_proxy_neigh'
require_relative 'updown/ip_route'
require_relative 'updown/ip_rule'
require_relative 'updown/link_mtu_up_down'
require_relative 'updown/loopback'
require_relative 'updown/openvpn'
require_relative 'updown/radvd'
require_relative 'updown/tunnel'
require_relative 'updown/vlan'
require_relative 'updown/wlan'
require_relative 'updown/ip_sec_connect'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            class UpDowner
              attr_reader :tastes
              def initialize(result)
                @result = result
                # @updos = []
                @tastes = []
              end
              def add(iface, ud)
                # @updos.push(ud)
                @tastes.each do |t|
                  dispatch = t.dispatch[ud.class.name]
                  throw "unknown dispatch for #{t.class.name} on #{ud.class.name}" unless dispatch
                  dispatch.call(iface, ud)
                end
                self
              end

              def taste(taste)
                @tastes.push(taste)
                taste.result = @result
                self
              end

              def commit
                @tastes.each do |ud|
                  ud.commit
                end
                # @updos.each do |ud|
                #   Construqt.logger.info "#{ud.class.name.split("::").last}=>#{@tastes.map{|f| f.class.name.split("::").last}.join(",")}"
                # end
                # binding.pry
              end
            end
          end
        end
      end
    end
  end
end
