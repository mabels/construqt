module Construqt
  module Packages
    class Package
      ME = :me
      MOTHER = :mother
      BOTH = :both
      attr_reader :name, :target
      def initialize(name, target)
        @name = name
        @target = target
      end
    end

    class Artefact
      attr_reader :name, :packages, :commands
      def initialize(name)
        @name = name
        @packages = {}
        @commands = []
      end
      def add(name)
        @packages[name] ||= Package.new(name, Package::ME)
        self
      end
      def both(name)
        @packages[name] ||= Package.new(name, Package::BOTH)
        self
      end
      def mother(name)
        @packages[name] ||= Package.new(name, Package::MOTHER)
        self
      end
      def cmd(cmd)
        @commands << cmd
        self
      end
    end

    class Builder
      attr_reader :artefacts
      def initialize()
        @artefacts = { }
        cp = Construqt::Resources::Component
        [
          cp::UNREF, cp::NTP, cp::USB_MODESWITCH,
          cp::VRRP, cp::FW4, cp::FW6, cp::IPSEC,
          cp::SSH, cp::BGP, cp::OPENVPN, cp::DNS,
          cp::RADVD, cp::CONNTRACKD, cp::LXC,
          cp::DOCKER, cp::DHCPRELAY, cp::DNSMASQ,
          cp::WIRELESS
        ].each do |c|
          self.register(c)
        end
      end
      def list(components)
        components.map do |name|
          ret = @artefacts[name]
          binding.pry unless ret
          throw "component name not found #{name}" unless ret
          ret
        end
      end

      def has(cname)
        @artefacts[cname.to_sym]
      end

      def register(component_name)
        name = component_name
        name = component_name.name unless name.kind_of?(String) or name.kind_of?(Symbol)
        @artefacts[name.to_sym] ||= Artefact.new(component_name)
      end
    end
  end
end
