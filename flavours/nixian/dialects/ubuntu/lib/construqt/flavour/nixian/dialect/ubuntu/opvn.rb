
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Opvn #< OpenStruct
            include Construqt::Cables::Plugin::Single
            attr_accessor :delegate
            attr_reader :address,:template,:plug_in,:network,:mtu,:clazz,:dh1024
            attr_reader :ipv6,:push_routes,:cacert,:name,:hostcert,:hostkey
            def initialize(cfg)
              @name = cfg['name']
              @address = cfg['address']
              @template = cfg['template']
              @plug_in = cfg['plug_in']
              @network = cfg['network']
              @mtu = cfg['mtu']
              @clazz = cfg['clazz']
              @ipv6 = cfg['ipv6']
              @push_routes = cfg['push_routes']
              @cacert = cfg['cacert']
              @hostcert = cfg['hostcert']
              @hostkey = cfg['hostkey']
              @dh1024 = cfg['dh1024']
            end

            def self.header(host)
              return unless host.has_interface_with_component?(Construqt::Resources::Component::OPENVPN)
              host.result.add(self, Construqt::Util.render(binding, "ovpn_pam.erb"), Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::OPENVPN), "etc", "pam.d", "openvpn")
            end

            def build_config(host, opvn)
              iface = opvn.delegate
              local = iface.ipv6 ? host.id.first_ipv6.first_ipv6 : host.id.first_ipv4.first_ipv4
              return unless local
              push_routes = ""
              if iface.push_routes
                push_routes = iface.push_routes.routes.each{|route| "push \"route #{route.dst.to_string}\"" }.join("\n")
              end

              host.result.add(self, iface.cacert, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "ssl", "#{iface.name}-cacert.pem")
              host.result.add(self, iface.hostcert, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "ssl", "#{iface.name}-hostcert.pem")
              host.result.add(self, iface.hostkey, Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "ssl", "#{iface.name}-hostkey.pem")
              host.result.add(self, iface.dh1024, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "ssl", "#{iface.name}-dh1024")
              host.result.add(self, Construqt::Util.render(binding, "ovpn_config.erb"), Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "#{iface.name}.conf")
            end
          end
        end
      end
    end
  end
end
