require 'resolv'
require_relative 'firewalls/i_c_m_p.rb'
require_relative 'firewalls/actions.rb'
require_relative 'firewalls/ipv4_ipv6.rb'
require_relative 'firewalls/tcp_mss.rb'
require_relative 'firewalls/attach_interface.rb'
require_relative 'firewalls/attached_firewall.rb'
require_relative 'firewalls/protocols.rb'
require_relative 'firewalls/log.rb'
require_relative 'firewalls/action_and_interface.rb'
require_relative 'firewalls/to_dest_from_source.rb'
require_relative 'firewalls/from_is_in_out_bound.rb'
require_relative 'firewalls/ports.rb'
require_relative 'firewalls/fw_token.rb'
require_relative 'firewalls/fw_ip_address.rb'
require_relative 'firewalls/fw_ip_addresses.rb'
require_relative 'firewalls/input_output_only.rb'
require_relative 'firewalls/from_to.rb'
require_relative 'firewalls/raw_entry.rb'
require_relative 'firewalls/raw.rb'
require_relative 'firewalls/nat_entry.rb'
require_relative 'firewalls/nat.rb'
require_relative 'firewalls/mangle.rb'
require_relative 'firewalls/forward_entry.rb'
require_relative 'firewalls/forward.rb'
require_relative 'firewalls/host_entry.rb'
require_relative 'firewalls/host.rb'
require_relative 'firewalls/firewall.rb'

module Construqt
  module Firewalls

    FIREWALLS = {}

    def self.add(name = nil, &block)
      if name == nil
        fw = Firewall.new(name)
      else
        throw "firewall with this name exists #{name}" if FIREWALLS[name]
        fw = FIREWALLS[name] = Firewall.new(name)
      end

      block.call(fw)
      fw
    end

    def self.exists?(name)
      FIREWALLS[name]
    end

    def self.find(name)
      ret = FIREWALLS[name]
      throw "firewall with this name #{name} not found" unless FIREWALLS[name]
      ret
    end
  end
end
