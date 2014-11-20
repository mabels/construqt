require_relative("parser")
require_relative("renderer")

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
    config = []

    delta["addedBonds"].each do |addedBond|
      config << "trunk " + newSwitchConfig.bondConfigs[addedBond].ports.join(",") + " #{addedBond} Trunk"
    end

    delta["removedBonds"].each do |removedBond|
      config << "no trunk " + oldSwitchConfig.bondConfigs[removedBond].ports.join(",")
    end

    delta["bondChanges"].each do |channel,bondDelta|
      config << "trunk " + bondDelta["addedPorts"].join(",") + " #{channel} Trunk" unless bondDelta["addedPorts"].length==0
      config << "no trunk " + bondDelta["removedPorts"].join(",") unless bondDelta["removedPorts"].length==0
    end

    delta["addedPorts"].each do |addedPort|
      newSwitchConfig.portConfigs[addedPort].vlans.each do |vlanid,conf|
        config << "vlan " + vlanid.to_s
        config << "   " + (conf["tagged"] ? "tagged" : "untagged") + " " + addedPort.to_s
        config << "   exit"
      end
    end

    delta["removedPorts"].each do |removedPort|
      oldSwitchConfig.portConfigs[removedPort].vlans.each do |vlanid,conf|
        if (!delta["removedVlans"].include?(vlanid))
          config << "vlan " + vlanid.to_s
          config << "   no " + (conf["tagged"] ? "tagged" : "untagged") + " " + removedPort.to_s
          config << "   exit"
        end
      end
    end

    delta["portChanges"].each do |changedPort,portDelta|
      (portDelta["addedVlans"] + portDelta["newlytagged"] + portDelta["newlyuntagged"]).each do |vlanid|
        config << "vlan " + vlanid.to_s
        config << "   " + (newSwitchConfig.portConfigs[changedPort].vlans[vlanid]["tagged"] ? "tagged" : "untagged") + " " +
          newSwitchConfig.portConfigs[changedPort].port.to_s
        config << "   exit"
      end
    end

    delta["addedVlans"].each do |addedVlan|
      config << "vlan " + addedVlan.to_s
      config << "   name \"" + newSwitchConfig.vlanConfigs[addedVlan].name + "\""
      config << "   exit"
    end

    delta["vlanChanges"].each do |addedVlan,vlanDelta|
      config << "vlan " + addedVlan.to_s
      config << "   name \"" + vlanDelta["newName"] + "\""
      config << "   exit"
    end

    delta["removedVlans"].each do |removedVlan|
      config << "no vlan " + removedVlan.to_s
    end

    config.join("\n")
  end
end

Flavour.parsers["hp-procurve"]=HpSwitchConfigParser
Flavour.renderers["hp-procurve"]=HpDeltaCommandRenderer
