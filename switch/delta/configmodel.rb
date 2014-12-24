module Construqt
  module SwitchDelta

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
  end
end
