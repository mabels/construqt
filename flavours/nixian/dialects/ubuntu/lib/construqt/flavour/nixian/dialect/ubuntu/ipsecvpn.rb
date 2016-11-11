require_relative 'base_device'
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class IpsecVpn
            include BaseDevice
            include Construqt::Cables::Plugin::Multiple
            attr_reader :left_interface, :right_interface, :ipv6_proxy
            attr_reader :leftpsk, :users, :right_address, :auth_method
            attr_reader :leftcert
            def initialize(cfg)
              base_device(cfg)
              @left_interface = cfg['left_interface']
              @left_cert = cfg['left_cert']
              @right_interface = cfg['right_interface']
              @ipv6_proxy = cfg['ipv6_proxy']
              @leftpsk = cfg['leftpsk']
              @users = cfg['users']
              @right_address = cfg['right_address']
              @auth_method = cfg['auth_method']
            end

            def build_config(host, iface, node)
              #puts ">>>>>>>>>>>>>>>>>>>>>>#{host.name} #{iface.name}"
              # binding.pry
              Device.build_config(host, iface, node, nil, nil, nil, true)
              render_ipv6_proxy(iface)
              if iface.leftpsk
                comment = "#{host.name}-#{iface.name}"
                iface.left_interface.address.ips.each do |ip|
                  self.host.result.ipsec_secret.add_any_psk(ip.to_s, Util.password(iface.leftpsk), comment)
                  comment = nil
                end
              end
              self.host.result.ipsec_secret.add_users_psk(host)

              self.host.result.add(:ipsec, render_ikev1(host, iface), Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "ipsec.conf")
              self.host.result.add(:ipsec, render_ikev2(host, iface), Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "ipsec.conf")
            end

            def render_ipv6_proxy(iface)
              return unless iface.ipv6_proxy
              host.result.add(self, Construqt::Util.render(binding, "ipsecvpn_updown.erb"),
                Construqt::Resources::Rights.root_0755, "etc", "ipsec.d", "#{iface.left_interface.name}-ipv6_proxy_updown.sh")
            end

            def render_ikev1(host, iface)
              conn = OpenStruct.new
              conn.keyexchange = "ikev1"
              conn.leftauth = "psk"
              conn.left = [iface.left_interface.address.first_ipv4,iface.left_interface.address.first_ipv6].compact.join(",")
              conn.leftid = host.region.network.fqdn(host.name)
              conn.leftsubnet = "0.0.0.0/0,2000::/3"
              if iface.ipv6_proxy
                conn.leftupdown = "/etc/ipsec.d/#{iface.left_interface.name}-ipv6_proxy_updown.sh"
                conn.rightupdown = "/etc/ipsec.d/#{iface.left_interface.name}-ipv6_proxy_updown.sh"
              end

              conn.right = "%any"
              conn.rightsourceip = iface.right_address.ips.map{|i| i.network.to_string}.join(",")
              conn.rightauth = "psk"
              if iface.auth_method == :radius
                conn.rightauth2 = "xauth-radius"
              else
                conn.rightauth2 = "xauth"
              end

              conn.rightsendcert = "never"
              conn.auto = "add"
              render_conn(host, iface, conn)
            end

            def render_ikev2(host, iface)
              conn = OpenStruct.new
              conn.keyexchange = "ikev2"
              conn.leftauth = "pubkey"
              if iface.leftcert
                conn.leftcert = iface.leftcert.cert.name
                host.result.ipsec_secret.add_cert(iface.leftcert)
              end

              conn.left = [iface.left_interface.address.first_ipv4,iface.left_interface.address.first_ipv6].compact.join(",")
              conn.leftid = host.region.network.fqdn(host.name)
              conn.leftsubnet = "0.0.0.0/0,2000::/3"
              if iface.ipv6_proxy
                conn.leftupdown = "/etc/ipsec.d/#{iface.left_interface.name}-ipv6_proxy_updown.sh"
                conn.rightupdown = "/etc/ipsec.d/#{iface.left_interface.name}-ipv6_proxy_updown.sh"
              end

              conn.right = "%any"
              conn.rightsourceip = iface.right_address.ips.map{|i| i.network.to_string}.join(",")
              conn.rightauth = "eap-mschapv2"
              conn.eap_identity = "%any"
              conn.auto = "add"
              render_conn(host, iface, conn)
            end

            def render_conn(host, iface, conn)
              out = ["conn #{host.name}-#{iface.name}-#{conn.keyexchange}"]
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
