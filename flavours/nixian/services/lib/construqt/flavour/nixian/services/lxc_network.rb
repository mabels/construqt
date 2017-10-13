
module Construqt
  module Flavour
    module Nixian
      module Services

        class LxcNetwork
          attr_reader :iface
          def initialize(_iface)
            @iface = _iface
            @flags = "up"
          end

          def flags(flags)
            @flags = flags
            self
          end

          def link(link)
            @link = link
            self
          end

          def name(name)
            @name = name
            self
          end

          def get_mac
            (["00", "16"] + Digest::SHA1.hexdigest("#{@iface.plug_in.get_iface.host.name}:#{@iface.host.name}:#{@iface.name}")
              .scan(/../)[0,4]).join(":").downcase
          end

          def render
            return unless @iface.plug_in
            return Construqt::Util.render(binding, "lxc_network_config.erb")
          end

          def self.create_lxc_network_patcher(result, host, lxc)
            result.add(lxc,
                            Construqt::Util.render(binding, "lxc_network_update_network_in_config.rb"),
                            Construqt::Resources::Rights.root_0755, "etc", "lxc", "update_network_in_config")
            result.add(lxc,
                            Construqt::Util.render(binding, "lxc_network_update_config.rb"),
                            Construqt::Resources::Rights.root_0755, "etc", "lxc", "update_config")
            true
          end

          def self.render(result, host, lxc, networks)
            #binding.pry
            return if networks.empty?
            result.add(lxc, networks.map{|n| n.render}.join("\n"),
                            Construqt::Resources::Rights.root_0644,
                            "var", "lib", "lxc",
                            "#{networks.first.iface.host.name}.network.config")
          end
        end
      end
    end
  end
end
