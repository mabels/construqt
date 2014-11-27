require("switch-delta/parser.rb")
require("switch-delta/renderer.rb")

module Construct
  module SwitchDelta

    class DlinkSwitchConfigParser < SwitchConfigParser
      def parse(lines)
        sc = SwitchConfig.new
        vlanContext = nil
        portContext = nil
        bondContext=nil
        lines.each do |line|
          if (line =~ /^\s*vlan (\d+)\s*$/)
            vlanContext = $1
            #puts "Entering vlan context #{vlanContext}"
          elsif (vlanContext && line =~ /^\s*name\s+(\S+)\s*$/)
            #puts "Vlan name definition #{$1}"
            sc.getOrCreateVlanConfig(vlanContext).name=$1
          elsif (vlanContext && line =~ /^\s*(exit|end)\s*$/)
            #puts "Leaving vlan context #{vlanContext}"
            vlanContext = nil
          elsif (line =~ /^\s*interface ethernet  ?(#{PORTS_DEF_REGEXP})\s*$/)
            portContext = resolvePortDefinition($1)
            #puts "Entering port context #{portContext}"
          elsif (portContext && line =~ /^\s*switchport trunk native vlan (\d+)\s*$/)
            #puts "Adding port #{portContext} to untagged vlan #{$1}"
            portContext.each { |port| sc.getOrCreatePortConfig(port).addVlan($1, false) }
          elsif (portContext && line =~ /^\s*switchport trunk allowed vlan (#{PORTS_DEF_REGEXP})\s*$/)
            #puts "Adding port #{portContext} to tagged vlans #{$1}"
            resolvePortDefinition($1).each do |vlanid|
              portContext.each { |port| sc.getOrCreatePortConfig(port).addVlan(vlanid, true) }
            end
          elsif (portContext && line =~ /^\s*(exit|end)\s*$/)
            #puts "Leaving port context #{portContext}"
            portContext = nil
          elsif (line =~ /^\s*interface port-channel  ?(\d+)\s*$/)
            bondContext = $1
          elsif (bondContext && line =~ /^\s*channel-group ethernet ?([\d\/]+) mode active\s*$/)
            sc.getOrCreateBondConfig(bondContext).ports << $1
          elsif (bondContext && line =~ /^\s*(exit|end)\s*$/)
            #puts "Leaving bond context #{bondContext}"
            bondContext = nil
          end
        end
        sc
      end
    end

    class DlinkDeltaCommandRenderer < DeltaCommandRenderer
      def buildConfig(oldSwitchConfig, newSwitchConfig, delta)
        result = Construct::Flavour::Ciscian::Result.new(Host.new("test-switch-123", "dlink-dgs15xx"))

        delta["addedBonds"].each do |addedBond|
          result.add("interface port-channel #{addedBond}", Construct::Flavour::Ciscian::SingleValueVerb)
        end

        delta["removedBonds"].each do |removedBond|
          result.add("no interface port-channel #{addedBond}", Construct::Flavour::Ciscian::SingleValueVerb)
        end

        delta["bondChanges"].each do |channel,bondDelta|
          bondDelta["addedPorts"].each do |addedPort|
            result.add("interface ethernet #{addedPort}") do |section|
              section.add("channel-group #{channel} mode active", Construct::Flavour::Ciscian::SingleValueVerb)
            end
          end
        end

        (delta["addedPorts"] + delta["portChanges"].keys).each do |addedPort|
          allowedVlans=newSwitchConfig.portConfigs[addedPort].vlans.select { |vlanid,conf| conf["tagged"] }.keys
          nativeVlans=newSwitchConfig.portConfigs[addedPort].vlans.select { |vlanid,conf| conf["untagged"] }.keys
          if (allowedVlans.length + nativeVlans.length > 0)
            result.add("interface ethernet #{addedPort}") do |section|
              allowedVlans.each {|allowedVlan| section.add("switchport trunk allowed vlan", Construct::Flavour::Ciscian::RangeVerb).add(allowedVlan) }
              nativeVlans.each {|nativeVlan| section.add("switchport trunk native vlan", Construct::Flavour::Ciscian::RangeVerb).add(nativeVlan) }
            end
          end
        end

        delta["removedPorts"].each do |removedPort|
          result.add("interface ethernet #{removedPort}") do |section|
            oldSwitchConfig.portConfigs[removedPort].vlans.each do |vlanid,conf|
              mode = conf["tagged"] ? "allowed" : "native"
              section.add("no switchport trunk #{mode} vlan", Construct::Flavour::Ciscian::SingleValueVerb).add(vlanid.to_s)
            end
          end
        end

        (delta["addedVlans"] + delta["vlanChanges"].keys).each do |addedVlan|
          result.add("vlan #{addedVlan.to_s}") do |section|
            section.add("name", Construct::Flavour::Ciscian::StringVerb).add(newSwitchConfig.vlanConfigs[addedVlan].name)
          end
        end

        delta["removedVlans"].each do |removedVlan|
          result.add("no vlan #{removedVlan.to_s}", Construct::Flavour::Ciscian::SingleValueVerb)
        end

        result.commit
      end
    end

    Flavour.parsers["dlink_dgs15xx"]=DlinkSwitchConfigParser
    Flavour.renderers["dlink_dgs15xx"]=DlinkDeltaCommandRenderer
  end
end
