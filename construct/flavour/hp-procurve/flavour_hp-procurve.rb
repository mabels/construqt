require 'construct/flavour/flavour.rb'

module Construct
  module Flavour
    module HpProCurve
      def self.name
        'hp-procurve'
      end
      Construct::Flavour.add(self)

      class Result
        def initialize(host)
          @host = host
          @result = {}
        end
        def stripEthernet(port)
          port.slice! "ethernet "
          port
        end
        def portNeighbors?(port1, port2)
            port2.succ == port1 || port1.succ == port2
        end
        def createRangeDefinition(ports)
          ranges=[]
          lastPort=nil
          ports.sort.each do |port|
            if  (ranges.length>0 && portNeighbors?(port, ranges[ranges.length-1]["to"]))
              ranges[ranges.length-1]["to"] = port
            else
              ranges << {"from" => port, "to" => port}
            end
          end
          ranges = ranges.map do |range|
            range["from"] == range["to"] ? range["from"] : range["from"] +"-"+range["to"]
          end
          ranges.join(",")
        end
        def commit
          config=[]

          config += @result["bonds"]
          config << "\n"

          @result["vlans"].each do |vlan_id, cfgs|
            config << "vlan " + vlan_id.to_s + "\n"
            config << "   name \"" + cfgs["name"] + "\"\n"

            ["tagged", "untagged"].each do |t|
              if cfgs[t].length > 0
                config << "   #{t} "
                cfgs[t].map do |port|
                  stripEthernet(port)
                end
                config << createRangeDefinition(cfgs[t]) + "\n"
              end
            end
            config << "   exit\n\n"
          end
          Util.write_str(config.join(), File.join(@host.name, "vlans.cfg"))
        end
        def addVlan(port, vlan_id, name, untagged)
          unless @result["vlans"]
            @result["vlans"] = {}
          end
          unless @result["vlans"][vlan_id]
            @result["vlans"][vlan_id]={"name" => "", "tagged" => [], "untagged" => []}
          end
          @result["vlans"][vlan_id]["name"] = name
          @result["vlans"][vlan_id][untagged ? "untagged" : "tagged"] << port
        end
        def addBond(channel, devices)
          unless @result["bonds"]
            @result["bonds"] = []
          end

          devices = devices.map do |dev|
            stripEthernet(dev.name)
          end

          @result["bonds"] << "trunk " + createRangeDefinition(devices) + " " + channel + " Trunk\n"
        end
      end

      class Host
        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end
        def self.build_config(host, unused)
        end
      end

      class Device
        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end
        def self.build_config(host, device)
          return "" if device.template.nil?
          return "" if device.template.vlans.nil?
          device.template.vlans.each do |vlan|
            host.result.delegate.addVlan(device.name, vlan.vlan_id, vlan.description, vlan.untagged?)
          end
        end
      end

      class Bond
        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end
        def self.build_config(host, bond)
          host.result.delegate.addBond(bond.name, bond.interfaces)
          Device.build_config(host, bond)
        end
      end

      class NotImplemented
        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end
        def self.build_config(host, iface)
          throw "not implemented on this flavour"
        end
      end

      class Interface < OpenStruct
        def initialize(cfg)
          super(cfg)
        end
        def build_config(host, unused)
          self.clazz.build_config(host, self)
        end
      end

      def self.clazz(name)
        ret = {
          "opvn" => NotImplemented,
          "bond" => Bond,
          "bridge" => NotImplemented,
          "gre" => NotImplemented,
          "vrrp" => NotImplemented,
          "template" => NotImplemented,
          "vlan" => NotImplemented,
          "host" => Host,
          "device"=> Device,
          "result" => Result
        }[name]
        throw "class not found #{name}" unless ret
        ret
      end

      def self.create_interface(name, cfg)
        cfg['name'] = name
        Interface.new(cfg)
      end

    end
  end
end
