module Construqt
  module Flavour
    module Ciscian
      class Dell55xx
        def self.name
          'dell-55xx'
        end

        def initialize(result)
          @result=result
        end

        def commit
        end

        def sort_section_keys(keys)
          keys
        end

        def expand_vlan_device_name(device)
          expand_device_name(device, { "po" => "Trk%s", "ge" => "%s" })
        end

        def expand_device_name(device, map={ "po" => "Port-channel%s", "ge" => "gigabitethernet1/0/%s" })
          return device.delegate.dev_name if device.delegate.dev_name
          pattern = map[device.name[0..1]]
          throw "device not expandable #{device.name}" unless pattern
          pattern%device.name[2..-1]
        end

        def managment_access_list
          <<-OUT
          management access-list network
          permit service ssh
          permit service https vlan995
          permit service ssh vlan995
          permit service http vlan995
          permit service snmp vlan995
          deny service ssh
          exit
          OUT
        end

        def add_host(host)
          @result.add("port", Ciscian::SingleValueVerb).add("jumbo-frame")
          @result.add("hostname", Ciscian::SingleValueVerb).add(@result.host.name)
          @result.add("logging", Ciscian::LoggingHostVerb).host()
          @result.add("ip ssh server", Ciscian::SingleValueVerb)

          @result.add("snmp-server location", Ciscian::SingleValueVerb).add(@result.host.name)
          @result.add("snmp-server contact", Ciscian::SingleValueVerb).add("TODO")

          @result.add("clock timezone", Ciscian::SingleValueVerb).add("GMT +1")
          @result.add("clock summer-time", Ciscian::SingleValueVerb).add("GMT recurring eu")
          @result.add("clock source sntp", Ciscian::SingleValueVerb)
          @result.add("sntp unicast client enable", Ciscian::SingleValueVerb)
          @result.add("sntp server TODO poll", Ciscian::SingleValueVerb)

          @result.host.interfaces.values.each do |iface|
            next unless iface.delegate.address
            iface.delegate.address.routes.each do |route|
              @result.add("ip route #{route.dst.to_s} #{route.dst.netmask} #{route.via.to_s}", Ciscian::SingleValueVerb)
            end
          end
        end

        def add_iface(section)
            section.add("spanning-tree portfast auto")
            section.add("spanning-tree guard root")
            section.add("spanning-tree bpduguard enable")
            section.add("switchport mode trunk")
        end

        def add_device(device)
          @result.add("interface #{expand_device_name(device)}") do |section|
            add_iface(section)
          end
        end

        def add_bond(bond)
          @result.add("interface #{expand_device_name(bond)}") do |section|
            add_iface(section)
          end
        end

        def add_vlan(vlan)
          @result.add("vlan database") do |section|
            section.add("vlan").add(vlan.vlan_id)
          end
          if vlan.delegate.address
            @result.add("interface vlan #{vlan.delegate.vlan_id}") do |section|
              if vlan.delegate.address.first_ipv4
                section.add("ip address").add(vlan.delegate.address.first_ipv4.to_string)
              elsif vlan.delegate.address.dhcpv4?
                section.add("ip address").add("dhcp-bootp")
              end
            end
          end
        end

        def parse_line(line, lines, section, result)
          [TrunkVerb, Tagged
          ].find do |i|
            i.parse_line(line, lines, section, result)
          end
        end

        def clear_interface(line)
          line.to_s.split(/\s+/).map do |i|
            split = /^([^0-9]+)([0-9].*)$/.match(i)
            split ? split[1..-1] : i
          end.flatten.join(' ')
        end

        def block_end?(line)
          ['end','exit'].include?(line.strip)
        end


        class Tagged < PatternBasedVerb
          def self.section
            "tagged"
          end

          def self.patterns
            ["tagged {+ports}", "no tagged {-ports}", "untagged {+uports}", "no untagged {-uports}"]
          end
        end

        class TrunkVerb < PatternBasedVerb
          def self.section
            "trunk"
          end

          def self.patterns
            ["no trunk {-ports}", "trunk {+ports} Trk{*channel} Trunk"]
          end
        end
      end

      Construqt::Flavour::Ciscian.add_dialect(Dell55xx)
    end
  end
end
