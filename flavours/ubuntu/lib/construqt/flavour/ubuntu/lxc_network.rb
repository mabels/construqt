
module Construqt
  module Flavour
    module Ubuntu

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
          out = [
            "# Network configuration [#{@name}||""]:[#{@link}]",
            "lxc.network.type = #{@iface.plug_in.get_type}",
            "lxc.network.flags = #{@flags}",
            "lxc.network.link = #{@link}",
            "lxc.network.hwaddr = #{get_mac}"
          ]
          out << "lxc.network.name = #{@name}" if @name
          return out.join("\n")
        end

        def self.create_lxc_network_patcher(host, lxc)
          host.result.add(lxc, IO.read(File.join(File.dirname(__FILE__), "resources", "update_network_in_config.rb")),
                          Construqt::Resources::Rights.root_0755, "etc", "lxc", "update_network_in_config")
          host.result.add(lxc, IO.read(File.join(File.dirname(__FILE__), "resources", "update_config.rb")),
                          Construqt::Resources::Rights.root_0755, "etc", "lxc", "update_config")
          true
        end

        def self.render(host, lxc, networks)
          return if networks.empty?
          host.result.add(lxc, networks.map{|n| n.render}.join("\n"),
                          Construqt::Resources::Rights.root_0644,
                          "var", "lib", "lxc", networks.first.iface.host.name, "network.config")
        end
      end

    end
  end
end
