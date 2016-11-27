require_relative './ipsec/ipsec_cert_store'
require_relative './ipsec/ipsec_secret'
require_relative './result'
require_relative './etc_network_iptables'
require_relative './firewall'
module Construqt
  module Flavour
    module Nixian
      module Services
        class IpTables
          def initialize()
          end
        end

        class IpTablesOncePerHost

          attr_reader :host
          def initialize
            @etc_network_iptables = EtcNetworkIptables.new
          end

          def attach_host(host)
            @host = host
          end

          def activate(context)
            @context = context
          end

          def create(host, ifname, iface, family)
            throw 'interface must set' unless ifname
            Firewall.create_from_iface(ifname, iface, @etc_network_iptables)
            Firewall.create_from_iface(ifname, iface.delegate.vrrp.delegate, writer) if iface.delegate.vrrp
          end

          def commit
            result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::ResultOncePerHost)
            result.add(EtcNetworkIptables, @etc_network_iptables.commitv4,
              Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW4),
              'etc', 'network', 'iptables.cfg')
            result.add(EtcNetworkIptables, @etc_network_iptables.commitv6,
              Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW6),
              'etc', 'network', 'ip6tables.cfg')

            up_downer = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::UpDownerOncePerHost)
            up_downer.add(host, Tastes::Entities::IpTables.new())
          end
        end

        class IpTablesAction
        end

        class IpTablesFactory
          attr_reader :machine
          def initialize(service_factory)
            @machine = service_factory.machine
              .service_type(IpTables)
              .result_type(IpTablesOncePerHost)
              .depend(Result)
              .depend(UpDowner)
          end

          def produce(host, srv_inst, ret)
            IpTablesAction.new
          end
        end

      end
    end
  end
end


# def initialize(cfg)
#   super(cfg)
# end
#
# def clazz
#   "strongswan"
# end
#
#
# def build_config(host, iface, node)
#   #puts ">>>>>#{self.cfg.transport_family}"
#   if self.cfg.transport_family == Construqt::Addresses::IPV6
#     local_if = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(self.remote.first_ipv6) }
#     transport_left=self.remote.first_ipv6.to_s
#     transport_right=self.other.remote.service_ip.first_ipv6.to_s
#     leftsubnet = self.my.ips.select{|i| i.ipv6? }.map{|i| i.to_s }.first # join(',')
#     rightsubnet = self.other.my.ips.select{|i| i.ipv6? }.map{|i| i.to_s }.first #.join(',')
#     gt = "gt6"
#   else
#     local_if = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(self.remote.first_ipv4) }
#     transport_left=self.remote.first_ipv4.to_s
#     transport_right=self.other.remote.service_ip.first_ipv4.to_s
#     leftsubnet = self.my.ips.select{|i| i.ipv4? }.map{|i| i.to_s }.first # join(',')
#     rightsubnet = self.other.my.ips.select{|i| i.ipv4? }.map{|i| i.to_s }.first #.join(',')
#     gt = "gt4"
#   end
#
#   if leftsubnet.nil? or leftsubnet.empty? or
#      rightsubnet.nil? or rightsubnet.empty?
#     throw "we need a transport_left and transport_right for #{self.host.name}-#{self.other.host.name}"
#   end
#
#   if local_if.clazz == "vrrp"
#     writer = host.result.etc_network_vrrp(local_if.name)
#     writer.add_master("/usr/sbin/ipsec up #{self.host.name}-#{self.other.host.name} &", 1000)
#     writer.add_backup("/usr/sbin/ipsec down #{self.host.name}-#{self.other.host.name} &", -1000)
#     local_if.services << Construqt::Services::IpsecStartStop.new
#   else
#     end
#
#   host.result.ipsec_secret.add_psk(transport_right, cfg.password, cfg.name)
#   host.result.ipsec_secret.add_psk(self.other.host.name, cfg.password)
#
#   conn = OpenStruct.new
#   conn.leftid=self.host.name
#   conn.rightid=self.other.host.name
#   conn.left=(self.any && "%any") || transport_left
#   conn.right=(self.other.any && "%any") || transport_right
#   conn.leftsubnet=leftsubnet
#   if (self.other.sourceip)
#     conn.leftsourceip="%config"
#   end
#
#   conn.rightsubnet=rightsubnet
#   if (self.sourceip)
#     conn.rightsourceip=rightsubnet
#   end
#
#   conn.esp=self.cfg.cipher || "aes256-sha1-modp1536"
#   conn.ike=self.cfg.cipher || "aes256-sha1-modp1536"
#   conn.compress="no"
#   conn.ikelifetime="60m"
#   conn.keylife="20m"
#   conn.keyingtries="0"
#   conn.keyexchange=self.cfg.keyexchange || "ike"
#   conn.type="tunnel"
#   conn.authby="secret"
#   conn.dpdaction="restart"
#   conn.dpddelay="120s"
#   conn.dpdtimeout="180s"
#   conn.rekeymargin="3m"
#   conn.closeaction="restart"
#   conn.auto=self.auto || "start"
#   self.host.result.add(:ipsec, render_conn(conn),
#     Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "ipsec.conf")
# end
#
# def render_conn(conn)
#   out = ["conn #{self.host.name}-#{self.other.host.name}"]
#   conn.to_h.each do |k,v|
#     out << Util.indent("#{k}=#{v}", 3)
#   end
#   out.join("\n")
# end
