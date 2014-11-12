class VlanConfig
  attr_accessor :vlanid,:name
  def initialize(vlanId)
    @vlanId=vlanId
  end
  def compare(otherVlanConfig)
    throw "other vlan config must have the same vlanid" unless otherVlanConfig.vlanid == @vlanid
    if (@name != otherVlanConfig.name)
      result = { "newName" => @name }
    end
    result
  end
end

class BondConfig
  attr_accessor :channel,:ports
  def initialize(channel)
    @channel=channel
    @ports=[]
  end
  def compare(otherBondConfig)
    throw "other bond config must be on the same channel" unless otherBondConfig.channel == @channel
    result = {}
    result["addedPorts"] = @ports - otherBondConfig.ports
    result["removedPorts"] = otherBondConfig.ports - @ports
    result
  end
end

class PortConfig
  attr_reader :port, :vlans
  def initialize(port)
    @port=port
    @vlans = {}
  end
  def addVlan(vlanId, tagged)
    @vlans[vlanId]={"tagged" => tagged}
  end
  def validate
    throw "orphaned port: port #{port} is not member of any vlan." if vlans.empty?
    throw "multiple untagged vlans: port #{port} has more than one untagged vlan" if 1 < vlans.map{|vlanId,conf| conf["tagged"] ? 0 : 1}.inject(:+)
  end
  def compare(otherPortConfig)
    self.validate
    otherPortConfig.validate
    throw "other port config must be on the same port name" unless otherPortConfig.port == @port
    result = {}
    result["addedVlans"] = @vlans.keys - otherPortConfig.vlans.keys
    result["removedVlans"] = otherPortConfig.vlans.keys - @vlans.keys
    result["newlytagged"] = []
    result["newlyuntagged"] = []
    (@vlans.keys & otherPortConfig.vlans.keys).each do |vlanid|
      if (@vlans[vlanid]["tagged"] ^ otherPortConfig.vlans[vlanid]["tagged"])
        result[@vlans[vlanid]["tagged"] ? "newlytagged" : "newlyuntagged"] << vlanid
      end
    end
    result
  end
end

class SwitchConfig
  attr_reader :portConfigs,:vlanConfigs,:bondConfigs
  def initialize()
    @portConfigs={}
    @vlanConfigs={}
    @bondConfigs={}
  end
  def getOrCreatePortConfig(port)
    @portConfigs[port] = PortConfig.new(port) unless @portConfigs[port]
    @portConfigs[port]
  end
  def getOrCreateVlanConfig(vlanid)
    @vlanConfigs[vlanid] = VlanConfig.new(vlanid) unless @vlanConfigs[vlanid]
    @vlanConfigs[vlanid]
  end
  def getOrCreateBondConfig(channel)
    @bondConfigs[channel] = BondConfig.new(channel) unless @bondConfigs[channel]
    @bondConfigs[channel]
  end
  def compare(otherSwitchConfig)
    result = {}
    result["addedPorts"] = @portConfigs.keys - otherSwitchConfig.portConfigs.keys
    result["removedPorts"] = otherSwitchConfig.portConfigs.keys - @portConfigs.keys
    result["portChanges"] = {}
    (otherSwitchConfig.portConfigs.keys & @portConfigs.keys).each do |changedPort|
      result["portChanges"][changedPort] = @portConfigs[changedPort].compare(otherSwitchConfig.portConfigs[changedPort])
    end

    result["addedBonds"] = @bondConfigs.keys - otherSwitchConfig.bondConfigs.keys
    result["removedBonds"] = otherSwitchConfig.bondConfigs.keys - @bondConfigs.keys
    result["bondChanges"] = {}
    (otherSwitchConfig.bondConfigs.keys & @bondConfigs.keys).each do |changedChannel|
      result["bondChanges"][changedChannel] = @bondConfigs[changedChannel].compare(otherSwitchConfig.bondConfigs[changedChannel])
    end

    result["addedVlans"] = @vlanConfigs.keys - otherSwitchConfig.vlanConfigs.keys
    result["removedVlans"] = otherSwitchConfig.vlanConfigs.keys - @vlanConfigs.keys
    result["vlanChanges"] = {}
    (@vlanConfigs.keys & otherSwitchConfig.vlanConfigs.keys).each do |changedVlan|
      vlanChanges = @vlanConfigs[changedVlan].compare(otherSwitchConfig.vlanConfigs[changedVlan])
      result["vlanChanges"][changedVlan] = vlanChanges if vlanChanges
    end

    result
  end
end

class DeltaCommandRenderer
  def self.buildConfig(oldSwitchConfig, newSwitchConfig, delta)
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
        config << "vlan " + vlanid.to_s
        config << "   no " + (conf["tagged"] ? "tagged" : "untagged") + " " + removedPort.to_s
        config << "   exit"
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

    delta["removedVlans"].each do |vlanid|
      config << "vlan " + vlanid.to_s
      config << "   no " + (oldSwitchConfig.portConfigs[changedPort].vlans[vlanid]["tagged"] ? "tagged" : "untagged") + " " +
        oldSwitchConfig.portConfigs[changedPort].port.to_s
      config << "   exit"
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
      config << "no vlan " + addedVlan.to_s
    end

    config.join("\n")
  end

end

class SwitchConfigParser
  PORTS_DEF_REGEXP = "(Trk\\d+|\\d+|,|-)+"
  def self.resolvePortDefinition(portDef)
    ports = portDef.split(",").map do |rangeDef|
      range = rangeDef.split("-")
      if (range.length==1)
        range
      elsif (range.length==2)
        (range[0]..range[1]).map {|n| n }
      else
        throw "invalid range fpund #{rangeDef}"
      end
    end
    ports.flatten
  end
  def self.parse(lines)
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

oldConfig = []
while ( line = $stdin.gets )
  oldConfig << line.chomp
end
oldSwitchConfig = SwitchConfigParser.parse(oldConfig)

newConfig = []
while ( line = gets )
  newConfig << line
end
newSwitchConfig = SwitchConfigParser.parse(newConfig)

#puts "--- CONFIG ---"
delta = newSwitchConfig.compare(oldSwitchConfig)
puts DeltaCommandRenderer.buildConfig(oldSwitchConfig, newSwitchConfig, delta)
