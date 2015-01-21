
module Construqt
  module Flavour
    module Ubuntu
      module Racoon
        class Ipsec < OpenStruct
          def initialize(cfg)
            super(cfg)
          end

          def self.header(host)
            #binding.pry
            addrs = {}
            ifaces = {}
            host.ipsecs.each do |ipsec|
              [ipsec.left, ipsec.right].each do |iface|
                next if iface.host != host
                ifaces[iface.remote.interface.name] = iface.remote.interface
                if iface.remote.first_ipv4
                  addrs[iface.remote.first_ipv4.to_s] = "isakmp #{iface.remote.first_ipv4.to_s} [500];"
                end

                if iface.remote.first_ipv6
                  addrs[iface.remote.first_ipv6.to_s] = "isakmp #{iface.remote.first_ipv6.to_s} [500];"
                end
              end
            end

            return if addrs.empty?
            host.result.add(self, <<HEADER, Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "default", "racoon")
# do not edit generated file
#
# this a a evil hack to avoid a raise condition on starting the
# OS racoon in the same moment like our
if [ "$STARTED_BY_CONSTRUQT" = "" ]
then
  exit 0
fi
HEADER

            host.result.add(self, <<HEADER, Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "racoon", "racoon.conf")
# do not edit generated file
path pre_shared_key "/etc/racoon/psk.txt";
path certificate "/etc/racoon/certs";
log info;
listen {
            #{Util.indent(addrs.keys.sort.map{|k| addrs[k] }.join("\n"), "  ")}
  strict_address;
}
HEADER
          end

          #    def build_gre_config()
          #      iname = Util.clean_if("gt", self.other.host.name)
          #      writer = self.host.result.delegate.etc_network_interfaces.get(self.interface)
          #      writer.lines.add(<<UP)
          #up ip -6 tunnel add #{iname} mode ip6gre local #{self.my.first_ipv6} remote #{self.other.my.first_ipv6}
          #up ip -6 addr add #{self.my.first_ipv6.to_string} dev #{iname}
          #up ip -6 link set dev #{iname} up
          #UP
          #      writer.lines.add(<<DOWN)
          #down ip -6 tunnel del #{iname}
          #DOWN
          #    end

          def build_racoon_config(remote_ip)
            #binding.pry
            self.host.result.add(self, <<RACOON, Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "racoon", "racoon.conf")
# #{self.cfg.name}
remote #{remote_ip} {
  exchange_mode main;
  lifetime time 24 hour;

  proposal_check strict;
  dpd_delay 30;
  ike_frag on;                    # use IKE fragmentation
  proposal {
    encryption_algorithm aes256;
    hash_algorithm sha1;
    authentication_method pre_shared_key;
    dh_group modp1536;
  }
}
RACOON
          end

          def from_to_sainfo(my_ip, other_ip)
            if my_ip.network.to_s == other_ip.network.to_s
              my_ip_str = my_ip.to_s
              other_ip_str = other_ip.to_s
            else
              my_ip_str = my_ip.to_string
              other_ip_str = other_ip.to_string
            end

            self.host.result.add(self, <<RACOON, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::IPSEC), "etc", "racoon", "racoon.conf")
sainfo address #{my_ip_str} any address #{other_ip_str} any {
pfs_group 5;
encryption_algorithm aes256;
authentication_algorithm hmac_sha1;
compression_algorithm deflate;
lifetime time 1 hour;
}
RACOON
          end

          def from_to_ipsec_conf(dir, remote_my, remote_other, my, other)
            host.result.add(self, "# #{self.cfg.name} #{dir}", Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::IPSEC), "etc", "ipsec-tools.d", "ipsec.conf")
            if my.network.to_s == other.network.to_s
              spdadd = "spdadd #{my.to_s} #{other.to_s}  any -P #{dir}  ipsec esp/tunnel/#{remote_my}-#{remote_other}/unique;"
            else
              spdadd = "spdadd #{my.to_string} #{other.to_string}  any -P #{dir}  ipsec esp/tunnel/#{remote_my}-#{remote_other}/unique;"
            end

            host.result.add(self, spdadd, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::IPSEC), "etc", "ipsec-tools.d", "ipsec.conf")
          end

          def build_policy(family, remote_my, remote_other, my, other)
            #binding.pry
            my.ips.each do |my_ip|
              other.ips.each do |other_ip|
                next unless (family == Construqt::Addresses::IPV6 && (my_ip.ipv6? && my_ip.ipv6? == other_ip.ipv6?)) ||
                  (family == Construqt::Addresses::IPV4 && (my_ip.ipv4? && my_ip.ipv4? == other_ip.ipv4?))
                from_to_ipsec_conf("out", remote_my, remote_other, my_ip, other_ip)
                from_to_sainfo(my_ip, other_ip)
              end
            end

            other.ips.each do |other_ip|
              my.ips.each do |my_ip|
                next unless (family == Construqt::Addresses::IPV6 && (my_ip.ipv6? && my_ip.ipv6? == other_ip.ipv6?)) ||
                  (family == Construqt::Addresses::IPV4 && (my_ip.ipv4? && my_ip.ipv4? == other_ip.ipv4?))
                from_to_ipsec_conf("in", remote_other, remote_my, other_ip, my_ip)
                from_to_sainfo(other_ip, my_ip)
              end
            end
          end

          def psk(ip, cfg)
            [
              "# #{cfg.name}",
              "#{ip} #{Util.password(cfg.password)}"
            ].join("\n")
          end

          def build_config(unused, unused2)
            #      build_gre_config()
            if self.cfg.transport_family == Construqt::Addresses::IPV6
              throw "we need a remote ipv6 address #{self.cfg.name}" unless self.other.remote.first_ipv6
              throw "we need a local ipv6 address #{self.cfg.name}" unless self.remote.first_ipv6
              build_racoon_config(self.other.remote.first_ipv6.to_s)
              host.result.add(self, psk(self.other.remote.first_ipv6.to_s, cfg),
                              Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::IPSEC), "etc", "racoon", "psk.txt")
              build_policy(self.cfg.transport_family, self.remote.first_ipv6.to_s, self.other.remote.first_ipv6.to_s, self.my, self.other.my)
            else
              throw "we need a remote ipv4 address #{self.cfg.name}" unless self.other.remote.first_ipv4
              throw "we need a local ipv4 address #{self.cfg.name}" unless self.remote.first_ipv4
              build_racoon_config(self.other.remote.first_ipv4.to_s)
              host.result.add(self, psk(self.other.remote.first_ipv4.to_s, cfg),
                              Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::IPSEC), "etc", "racoon", "psk.txt")
              build_policy(self.cfg.transport_family, self.remote.first_ipv4.to_s, self.other.remote.first_ipv4.to_s, self.my, self.other.my)
            end
          end
        end
      end
      module StrongSwan
        class Ipsec < OpenStruct
          def initialize(cfg)
            super(cfg)
          end

          def self.header(host)
            host.result.add(self, <<HEADER, Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "ipsec.conf")
config setup
        uniqueids=yes
HEADER
          end

          def psk(ip, cfg)
            [
              "# #{cfg.name}",
              "#{ip} : PSK \"#{Util.password(cfg.password)}\""
            ].join("\n")
          end

          def build_config(unused, unused2)
            if self.cfg.transport_family == Construqt::Addresses::IPV6
              local_if = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(self.remote.first_ipv6) }
              transport_left=self.remote.first_ipv6.to_s
              transport_right=self.other.remote.first_ipv6.to_s
              leftsubnet = self.my.ips.select{|i| i.ipv6? }.map{|i| i.to_s }.join(',')
              rightsubnet = self.other.my.ips.select{|i| i.ipv6? }.map{|i| i.to_s }.join(',')
              gt = "gt6"
            else
              local_if = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(self.remote.first_ipv4) }
              transport_left=self.remote.first_ipv4.to_s
              transport_right=self.other.remote.first_ipv4.to_s
              leftsubnet = self.my.ips.select{|i| i.ipv4? }.map{|i| i.to_s }.join(',')
              rightsubnet = self.other.my.ips.select{|i| i.ipv4? }.map{|i| i.to_s }.join(',')
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

            self.host.result.add(self, <<RACOON, Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "ipsec.conf")
conn #{self.host.name}-#{self.other.host.name}
        left=#{transport_left}
        right=#{transport_right}
        leftsubnet=#{leftsubnet}
        rightsubnet=#{rightsubnet}
        esp=aes256-sha1-modp1536
        ike=aes256-sha1-modp1536
        compress=no
        ikelifetime=60m
        keylife=20m
        keyingtries=0
        keyexchange=#{self.cfg.keyexchange || "ike"}
        type=tunnel
        authby=secret
        dpdaction=restart
        dpddelay=120s
        dpdtimeout=180s
        rekeymargin=3m
        closeaction=restart
        auto=start
RACOON
          end

        end
      end
    end
  end
end
