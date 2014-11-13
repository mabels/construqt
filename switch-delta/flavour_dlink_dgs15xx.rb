require_relative("parser")
require_relative("renderer")

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
      elsif (line =~ /^\s*interface ethernet  ?([\d\/]+)\s*$/)
        portContext = $1
        #puts "Entering port context #{portContext}"
      elsif (portContext && line =~ /^\s*switchport trunk native vlan (\d+)\s*$/)
        #puts "Adding port #{portContext} to untagged vlan #{$1}"
        sc.getOrCreatePortConfig(portContext).addVlan($1, false)
      elsif (portContext && line =~ /^\s*switchport trunk allowed vlan (#{PORTS_DEF_REGEXP})\s*$/)
        #puts "Adding port #{portContext} to tagged vlans #{$1}"
        sc.getOrCreatePortConfig(portContext).addVlan(resolvePortDefinition($1), true)
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
    config = []

    delta["addedBonds"].each do |addedBond|
      config << "interface port-channel #{addedBond}"
    end

    delta["removedBonds"].each do |removedBond|
      config << "no interface port-channel #{removedBond}"
    end

    delta["bondChanges"].each do |channel,bondDelta|
      bondDelta["addedPorts"].each do |addedPort|
        config << "interface ethernet " + addedPort
        config << "   channel-group #{channel} mode active"
        config << "exit"
      end
    end

    (delta["addedPorts"] + delta["portChanges"].keys).each do |addedPort|
      config << "interface ethernet " + addedPort
      newSwitchConfig.portConfigs[addedPort].vlans.each do |vlanid,conf|
        mode = conf["tagged"] ? "allowed" : "native"
        config << "   switchport trunk #{mode} vlan " + vlanid.to_s
      end
      config << "   exit"
    end

    delta["removedPorts"].each do |removedPort|
      config << "interface ethernet " + removedPort
      oldSwitchConfig.portConfigs[removedPort].vlans.each do |vlanid,conf|
        mode = conf["tagged"] ? "allowed" : "native"
        config << "   no switchport trunk #{mode} vlan " + vlanid.to_s
      end
      config << "   exit"
    end

    (delta["addedVlans"] + delta["vlanChanges"].keys).each do |addedVlan|
      config << "vlan " + addedVlan.to_s
      config << "   name " + newSwitchConfig.vlanConfigs[addedVlan].name
      config << "   exit"
    end

    delta["removedVlans"].each do |removedVlan|
      config << "no vlan " + removedVlan.to_s
    end

    config.join("\n")
  end
end

Flavour.parsers["dlink_dgs15xx"]=DlinkSwitchConfigParser
Flavour.renderers["dlink_dgs15xx"]=DlinkDeltaCommandRenderer
