module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Ipsec
            class StrongSwan < OpenStruct
                def initialize(cfg)
                  super(cfg)
                end

                def self.header(host)
                  render_certs(host)
                  render_private_keys(host)
                  render_users(host)
                  host.result.add(self, <<HEADER, Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "ipsec.conf")
config setup
  uniqueids=yes
HEADER
                end

                def self.render_users(host)
                  #binding.pry
                  out = {}
                  host.interfaces.values.each do |iface|
                    next unless iface.kind_of?(Construqt::Flavour::Delegate::IpsecVpnDelegate)
                    next unless iface.users
                    iface.users.each do |user|
                      out[user.name] = user.psk
                    end
                  end

                  host.result.add(self, "# ipsec users", Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::IPSEC), "etc", "ipsec.secrets")
                  out.each do |name, psk|
                    host.result.add(self, <<USER, Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::IPSEC), "etc", "ipsec.secrets")
#{name} : XAUTH \"#{Util.password(psk)}\"
#{name} : EAP   \"#{Util.password(psk)}\"
USER
                  end
                end

                def self.render_private_keys(host)
                  host.result.add(self, "# ipsec private keys", Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::IPSEC), "etc", "ipsec.secrets")
                  host.region.network.cert_store.all_private.keys.each do |key|
                    host.result.add(self, ": RSA #{key}", Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::IPSEC), "etc", "ipsec.secrets")
                  end
                end

                def self.render_certs(host)
                  host.region.network.cert_store.all.each do |key, datas|
                    datas.each do |name, data|
                      host.result.add(self, data, Construqt::Resources::Rights.root_0600, "etc", "ipsec.d", key, name)
                    end
                  end
                end

                def psk(ip, cfg)
                  [
                    "# #{cfg.name}",
                    "#{ip} : PSK \"#{Util.password(cfg.password)}\"",
                    "#{self.other.host.name} : PSK \"#{Util.password(cfg.password)}\""
                  ].join("\n")
                end

                def build_config(unused, unused2)
                  #puts ">>>>>#{self.cfg.transport_family}"
                  if self.cfg.transport_family == Construqt::Addresses::IPV6
                    local_if = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(self.remote.first_ipv6) }
                    transport_left=self.remote.first_ipv6.to_s
                    transport_right=self.other.remote.first_ipv6.to_s
                    leftsubnet = self.my.ips.select{|i| i.ipv6? }.map{|i| i.to_s }.first # join(',')
                    rightsubnet = self.other.my.ips.select{|i| i.ipv6? }.map{|i| i.to_s }.first #.join(',')
                    gt = "gt6"
                  else
                    local_if = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(self.remote.first_ipv4) }
                    transport_left=self.remote.first_ipv4.to_s
                    transport_right=self.other.remote.first_ipv4.to_s
                    leftsubnet = self.my.ips.select{|i| i.ipv4? }.map{|i| i.to_s }.first # join(',')
                    rightsubnet = self.other.my.ips.select{|i| i.ipv4? }.map{|i| i.to_s }.first #.join(',')
                    gt = "gt4"
                  end

                  if local_if.clazz == "vrrp"
                    writer = host.result.etc_network_vrrp(local_if.name)
                    writer.add_master("/usr/sbin/ipsec up #{self.host.name}-#{self.other.host.name} &", 1000)
                    writer.add_backup("/usr/sbin/ipsec down #{self.host.name}-#{self.other.host.name} &", -1000)
                    local_if.services << Construqt::Services::IpsecStartStop.new
                  else
                    iname = local_if.name
                    if local_if.clazz == "gre"
                      iname = Util.clean_if(gt, iname)
                    end

                    writer = host.result.etc_network_interfaces.get(local_if, iname)
                    writer.lines.up("/usr/sbin/ipsec up #{self.host.name}-#{self.other.host.name} &", 1000)
                    writer.lines.down("/usr/sbin/ipsec down #{self.host.name}-#{self.other.host.name} &", -1000)
                  end

                  host.result.add(self, psk(transport_right, cfg),
                                  Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::IPSEC),
                                  "etc", "ipsec.secrets")

                  conn = OpenStruct.new
                  conn.leftid=self.host.name
                  conn.rightid=self.other.host.name
                  conn.left=(self.any && "%any") || transport_left
                  conn.right=(self.other.any && "%any") || transport_right
                  conn.leftsubnet=leftsubnet
                  if (self.other.sourceip)
                    conn.leftsourceip="%config"
                  end

                  conn.rightsubnet=rightsubnet
                  if (self.sourceip)
                    conn.rightsourceip=rightsubnet
                  end

                  conn.esp=self.cfg.cipher || "aes256-sha1-modp1536"
                  conn.ike=self.cfg.cipher || "aes256-sha1-modp1536"
                  conn.compress="no"
                  conn.ikelifetime="60m"
                  conn.keylife="20m"
                  conn.keyingtries="0"
                  conn.keyexchange=self.cfg.keyexchange || "ike"
                  conn.type="tunnel"
                  conn.authby="secret"
                  conn.dpdaction="restart"
                  conn.dpddelay="120s"
                  conn.dpdtimeout="180s"
                  conn.rekeymargin="3m"
                  conn.closeaction="restart"
                  conn.auto=self.auto || "start"
                  self.host.result.add(self, render_conn(conn), Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "ipsec.conf")
                end

                def render_conn(conn)
                  out = ["conn #{self.host.name}-#{self.other.host.name}"]
                  conn.to_h.each do |k,v|
                    out << Util.indent("#{k}=#{v}", 3)
                  end

                  out.join("\n")
                end
              end
            end
        end
      end
    end
  end
end
