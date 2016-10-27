
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Opvn #< OpenStruct
            include Construqt::Cables::Plugin::Single
            attr_accessor :delegate
            attr_reader :address,:template,:plug_in,:network,:mtu,:clazz,:dh
            attr_reader :listen,:push_routes,:cacert,:name,:hostcert,:hostkey,:host
            attr_reader :description, :firewalls, :protocols, :proto, :flavour
            attr_reader :services
            def initialize(cfg)
              @name = cfg['name']
              @host = cfg['host']
              @description = cfg['description']
              @flavour = cfg['flavour']
              @services = cfg['services']
              @firewalls = cfg['firewalls']
              @address = cfg['address']
              @template = cfg['template']
              @plug_in = cfg['plug_in']
              @network = cfg['network']
              @proto = cfg['proto']
              @mtu = cfg['mtu']
              @clazz = cfg['clazz']
              @listen = cfg['listen']
              @push_routes = cfg['push_routes']
              @cacert = cfg['cacert']
              @hostcert = cfg['hostcert']
              @hostkey = cfg['hostkey']
              @dh = cfg['dh']
            end

            def belongs_to
              [self.host]
            end

            def self.header(host)
              return unless host.has_interface_with_component?(Construqt::Resources::Component::OPENVPN)
              host.result.add(self, Construqt::Util.render(binding, "ovpn_pam.erb"), Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::OPENVPN), "etc", "pam.d", "openvpn")
            end

            def build_config(host, opvn, node)

              Device.build_config(host, opvn, node, nil, nil, nil, true)

              iface = opvn.delegate
              proto = iface.proto
              # binding.pry
              listen = if proto.end_with?("6")
                iface.listen.address.first_ipv6
              else
                iface.listen.address.first_ipv4
              end
              throw "no address found for #{proto}" unless listen
              push_routes = ""
              if iface.push_routes
                push_routes = iface.push_routes.routes.each{|route| "push \"route #{route.dst.to_string}\"" }.join("\n")
              end

              writer = host.result.etc_network_interfaces.get(iface)
              writer.lines.up("mkdir -p /dev/net")
              writer.lines.up("mknod /dev/net/tun c 10 200")
              writer.lines.up("/usr/sbin/openvpn --config /etc/openvpn/#{iface.name}.conf")
              writer.lines.down("kill $(cat /run/openvpn.#{iface.name}.pid)")

              host.result.add(self, iface.cacert, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "ssl", "#{iface.name}-cacert.pem")
              host.result.add(self, iface.hostcert, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "ssl", "#{iface.name}-hostcert.pem")
              host.result.add(self, iface.hostkey, Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "ssl", "#{iface.name}-hostkey.pem")
              host.result.add(self, iface.dh, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "ssl", "#{iface.name}.dh")
              host.result.add(self, Construqt::Util.render(binding, "ovpn_config.erb"), Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "#{iface.name}.conf")
            end
          end
        end
      end
    end
  end
end
