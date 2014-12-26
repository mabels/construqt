require("switch-delta/parser.rb")
require("switch-delta/renderer.rb")

module Construqt
  module SwitchDelta

    class HpSwitchConfigParser < SwitchConfigParser
      def parse(lines)
        sc = SwitchConfig.new
        vlanContext = nil
        lines.each do |line|
          if (line =~ /^\s*vlan (\d+)\s*$/)
            vlanContext = $1
            #puts "Entering vlan context #{vlanContext}"
          elsif (vlanContext && line =~ /^\s*name "(.+)"\s*$/)
            #puts "Vlan name definition #{$1}"
            sc.getOrCreateVlanConfig(vlanContext).name=$1
          elsif (vlanContext && line =~ /^\s*(un|)tagged (#{PORTS_DEF_REGEXP})\s*$/)
            #puts "PortRange #{$1} => #{$2}"
            resolvePortDefinition($2).each do |port|
              #puts "Adding port #{port} to vlan #{vlanContext}"
              sc.getOrCreatePortConfig(port).addVlan(vlanContext, $1=="")
            end
          elsif (line =~ /^trunk (#{PORTS_DEF_REGEXP}) (Trk\d+) Trunk\s*$/)
            sc.getOrCreateBondConfig($3).ports += resolvePortDefinition($1)
          end
          if (vlanContext && line =~ /^\s*exit\s*$/)
            #puts "Leaving vlan context #{vlanContext}"
            vlanContext = nil
          end
        end
        sc
      end
    end

    class HpDeltaCommandRenderer < DeltaCommandRenderer
      def buildConfig(oldSwitchConfig, newSwitchConfig, delta)
        result = Construqt::Flavour::Ciscian::Result.new(Host.new("test-switch-123", "hp-2510g"))

        delta["addedBonds"].each do |addedBond|
          newSwitchConfig.bondConfigs[addedBond].ports.each do |port|
            result.add("#{addedBond}", Construqt::Flavour::Ciscian::Hp2510g::TrunkVerb).add(port)
          end
        end

        delta["removedBonds"].each do |removedBond|
          result.add("no trunk " + oldSwitchConfig.bondConfigs[removedBond].ports.join(","), Construqt::Flavour::Ciscian::SingleValueVerb)
        end

        delta["bondChanges"].each do |channel,bondDelta|
          result.add("trunk " + bondDelta["addedPorts"].join(",") + " #{channel} Trunk", Construqt::Flavour::Ciscian::SingleValueVerb) unless bondDelta["addedPorts"].length==0
          result.add("no trunk " + bondDelta["removedPorts"].join(","), Construqt::Flavour::Ciscian::SingleValueVerb) unless bondDelta["removedPorts"].length==0
        end

        delta["addedPorts"].each do |addedPort|
          newSwitchConfig.portConfigs[addedPort].vlans.each do |vlanid,conf|
            result.add("vlan #{vlanid.to_s}") do |section|
              section.add(conf["tagged"] ? "tagged" : "untagged").add(addedPort.to_s)
            end
          end
        end

        delta["removedPorts"].each do |removedPort|
          oldSwitchConfig.portConfigs[removedPort].vlans.each do |vlanid,conf|
            if (!delta["removedVlans"].include?(vlanid))
              result.add("vlan #{vlanid.to_s}") do |section|
                section.add("no " + conf["tagged"] ? "tagged" : "untagged", Construqt::Flavour::Ciscian::RangeVerb).add(removedPort.to_s)
              end
            end
          end
        end

        delta["portChanges"].each do |changedPort,portDelta|
          (portDelta["addedVlans"] + portDelta["newlytagged"] + portDelta["newlyuntagged"]).each do |vlanid|
            result.add("vlan #{vlanid.to_s}") do |section|
              section.add(newSwitchConfig.portConfigs[changedPort].vlans[vlanid]["tagged"] ? "tagged" : "untagged", Construqt::Flavour::Ciscian::RangeVerb).add(newSwitchConfig.portConfigs[changedPort].port.to_s)
            end
          end
        end

        delta["addedVlans"].each do |addedVlan|
          result.add("vlan #{addedVlan.to_s}") do |section|
            section.add("name", Construqt::Flavour::Ciscian::StringVerb).add(newSwitchConfig.vlanConfigs[addedVlan].name)
          end
        end

        delta["vlanChanges"].each do |addedVlan,vlanDelta|
          result.add("vlan #{addedVlan.to_s}") do |section|
            section.add("name", Construqt::Flavour::Ciscian::StringVerb).add(vlanDelta["newName"])
          end
        end

        delta["removedVlans"].each do |removedVlan|
          result.add("no vlan #{removedVlan.to_s}")
        end

        result.commit
      end
    end

    Flavour.parsers["hp-2510g"]=HpSwitchConfigParser
    Flavour.renderers["hp-2510g"]=HpDeltaCommandRenderer

  end
end
