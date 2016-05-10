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
      def initialize()
        @artefacts = {}
      end
      def list(components)
        components.map do |name|
          ret = @artefacts[name]
          binding.pry unless ret
          throw "component name not found #{name}" unless ret
          ret
        end
      end

      def register(component_name)
        @artefacts[component_name] ||= Artefact.new(component_name)
      end
    end
  end
end
