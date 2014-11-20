require 'construct/flavour/flavour.rb'

module Construct
  module Flavour
    module DlinkDgs15xx
      def self.name
        'dlink-dgs15xx'
      end

      Construct::Flavour.add(self)

      class Result
        def initialize(host)
          @host = host
          @result = {}
        end

        def host
          @host
        end

        def empty?(name)
          not @result[name]
        end

        def add(block, clazz)
          @result[clazz] = [] unless @result[clazz]
          @result[clazz] << block unless block.strip == ""
        end

        def commit
          @result.each do |clazz, block|
            Util.write_str(block.join("\n"), File.join(@host.name, "#{clazz}.cfg"))
          end
        end
      end

      class Device < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end

        def self.untagged(template)
          return "" if template.nil?
          return "" if template.vlans.nil?
          untagged = template.vlans.select{|i| i.untagged? }
          throw "multiple untagged not allowed" if untagged.length > 1
          if untagged.length == 1
            "switchport trunk native vlan #{untagged.first.vlan_id}"
          else
            ""
          end
        end

        def self.tagged(template)
          return "" if template.nil?
          return "" if template.vlans.nil?
          range = []
          vlan_ids = template.vlans.select{|i| i.tagged? }.map{|i| i.vlan_id}.sort{|a,b| a<=>b }
          vlan_ids.each_with_index do |vlan_id, idx|
            #        binding.pry
            if idx == 0
              range << [vlan_id, vlan_id]
            elsif range.last.last == vlan_id-1 # last pushed range last vlan_id see line before
              range.last[1] = vlan_id
            else
              range << [vlan_id, vlan_id]
            end
          end

          if range.length
            range_str = range.map{|i| i.first == i.last ? i.first.to_s : "#{i.first}-#{i.last}" }.join(',')
            "switchport trunk allowed vlan #{range_str}"
          else
            ""
          end
        end

        def build_config(host, iface)
          self.class.build_config(host, iface)
        end

        def self.build_config(host, iface)
          host.result.add("interface #{iface.name}", "device")
          host.result.add("  flowcontrol off", "device")
          host.result.add("  max-rcv-frame-size #{iface.delegate.mtu || 9126}", "device")
          host.result.add("  snmp trap link-status", "device")
          host.result.add("  switchport mode trunk", "device")
          host.result.add("  #{untagged(iface.delegate.template)}", "device")
          host.result.add("  #{tagged(iface.delegate.template)}", "device")
          host.result.add("end", "device")
        end
      end

      class Vrrp < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end

        def self.build_config(host, iface)
          "# this is a generated file do not edit!!!!!"
        end
      end

      class Bond < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def self.header(path)
        end

        def build_config(host, iface)
          throw "need template" unless iface.template
          throw "need intefaces" unless iface.interfaces
          host.result.add("interface #{iface.name}", "device")
          #configuration for port-channel goes here
          host.result.add("end","device")

          iface.interfaces.each do |i|
            host.result.add("interface #{i.name}", "device")
            host.result.add("  channel-group #{iface.name} mode active", "device")
            host.result.add("end", "device")
          end
        end
      end

      class Vlan < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
          vlan = iface.name.split('.')
          throw "vlan name not valid if.# => #{iface.name}" if vlan.length != 2 ||
            !vlan.first.match(/^[0-9a-zA-Z]+$/) ||
            !vlan.last.match(/^[0-9]+/) ||
            !(1 <= vlan.last.to_i && vlan.last.to_i < 4096)
          Device.build_config(host, iface)
        end
      end

      class Bridge
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
          throw "not implemented bridge on ubuntu"
        end
      end

      class Host < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end

        def build_config(host, unused)
          host.interfaces.values.each do |interface|
            #puts "interface=>#{host.name} #{interface.name}"
          end
        end
      end

      module Gre
        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end

        def self.build_config(host, iface)
          throw "not implemented bridge on ubuntu"
        end
      end

      module Opvn
        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end

        def self.build_config(host, iface)
          throw "not implemented bridge on ubuntu"
        end
      end

      module Template
      end

      def self.clazz(name)
        ret = {
          "opvn" => Opvn,
          "gre" => Gre,
          "host" => Host,
          "device"=> Device,
          "vrrp" => Vrrp,
          "bridge" => Bridge,
          "template" => Template,
          "bond" => Bond,
          "vlan" => Vlan,
          "result" => Result
        }[name]
        #binding.pry if name == "device"
        throw "class not found #{name}" unless ret
        ret
      end

      def self.create_host(name, cfg)
        cfg['name'] = name
        cfg['result'] = nil
        host = Host.new(cfg)
        host.result = Result.new(host)
        host
      end

      def self.create_interface(name, cfg)
        cfg['name'] = name
        clazz(cfg['clazz']).new(cfg)
        #cfg['name'] = name
        #Interface.new(cfg)
      end

      def self.create_bgp(cfg)
        "# this is a generated file do not edit!!!!!"
      end

      def self.create_ipsec(cfg)
        "# this is a generated file do not edit!!!!!"
      end
    end
  end
end
