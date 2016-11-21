module Construqt
  module Flavour
    module Nixian
      module Services
        class Yubikey
          include Construqt::Util::Chainable
          attr_accessor :servers, :name, :services
          chainable_attr :adv_autonomous
          def initialize(name)
            self.name = name
          end
        end

        class YubikeyImpl
          attr_reader :service_type
          def initialize
            @service_type = Yubikey
          end

          def attach_service(service)
            @service = service
          end

          def build_interface(host, ifname, iface, writer)
          end
          #unless ykeys.empty?
          #  host.result.add(self, ykeys.join("\n"), Construqt::Resources::Rights.root_0644, "etc", "yubikey_mappings")
          #end
          #host.result.add(self, Construqt::Util.render(binding, "ovpn_pam.erb"), Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::OPENVPN), "etc", "pam.d", "openvpn")

        end
      end
    end
  end
end
