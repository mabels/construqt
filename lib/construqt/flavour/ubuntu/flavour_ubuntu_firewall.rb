module Construqt
  module Flavour
    module Ubuntu
      module Firewall
        class ToFrom
          attr_reader :request_direction, :respond_direction, :rule, :ifname, :writer, :section
          def initialize(ifname, rule, section, writer = nil)
            @rule = rule
            @section = section
            @ifname = ifname
            @writer = writer
          end

          def set_writer(writer)
            @writer = writer
            self
          end

          def set_rule(rule)
            @rule = rule
            self
          end

          def request_direction(family)
            RequestDirection.new(self, family)
          end

          def respond_direction(family)
            RespondDirection.new(self, family)
          end

          class Direction
            attr_reader :to_from, :family, :to_from, :begin, :end, :middle
            def initialize(to_from, family)
              @to_from = to_from
              @family = family
              @begin = @end = @middle = ""
            end

            def interface_direction(dir)
              @interface_direction = dir
              self
            end

            def get_interface_direction
              @interface_direction
            end

            def set_writer(writer)
              @to_from.set_writer(writer)
              self
            end

            def ifname
              "#{@interface_direction} #{to_from.ifname}"
            end

            def action
              to_from.rule.get_action
            end

            def row(line, table_name = nil)
              factory = to_from.writer.create
              factory.table(table_name) unless table_name.nil?
              factory.row("#{line}")
            end

            def protocols
              pl = []
              @to_from.rule.get_protocols(@family).each do |proto|
                pl << "-p #{proto}"
              end

              pl << '' if pl.empty?
              pl
            end

            def link_local?
              @to_from.rule.link_local?
            end

            def for_family?(family)
              (family == Construqt::Addresses::IPV4 && @to_from.rule.ipv4?) || (family == Construqt::Addresses::IPV6 && @to_from.rule.ipv6?)
            end

            def push_begin(str)
              @begin = @begin + Construqt::Util.space_before(str)
              self
            end

            def push_middle(str)
              @middle = @middle + Construqt::Util.space_before(str)
              self
            end

            def push_end(str)
              @end = @end + Construqt::Util.space_before(str)
              self
            end

            def set_protocols(protocol)
              push_begin(protocol)
              if (to_from.rule.get_dports && !to_from.rule.get_dports.empty?) ||
                  (to_from.rule.get_sports && !to_from.rule.get_sports.empty?)
                push_middle("-m multiport")
              end
            end
          end

          class RequestDirection < Direction
            def initialize(to_from, family)
              super(to_from, family)
              self.interface_direction("-o")
            end

            def src_ip_list
              to_from.rule.from_list(family)
            end

            def dst_ip_list
              to_from.rule.to_list(family)
            end

            def set_protocols(protocol)
              super(protocol)

              if to_from.rule.connection?
                push_middle("-m state --state NEW,ESTABLISHED")
              end

              if to_from.rule.get_log
                push_end("--nflog-prefix :#{to_from.rule.get_log}#{self.ifname.gsub(/[^a-zA-Z0-9]/,":")}")
              end

              if to_from.rule.get_dports && !to_from.rule.get_dports.empty?
                push_middle("--dports #{to_from.rule.get_dports.join(",")}")
              end

              if to_from.rule.get_sports && !to_from.rule.get_sports.empty?
                push_middle_right("--sports #{to_from.rule.get_sports.join(",")}")
              end

              if to_from.rule.icmp? && to_from.rule.get_type
                state = {
                  Construqt::Firewalls::ICMP::Ping => {
                    Construqt::Addresses::IPV4 => "-m icmp --icmp-type 8/0",
                    Construqt::Addresses::IPV6 => "--icmpv6-type 128",
                  }
                }[to_from.rule.get_type][family]
                throw "state for #{to_from.rule.get_type} #{family}" unless state
                push_middle(state)
              end
            end
          end

          class RespondDirection < Direction
            def initialze(to_from, family)
              super(to_from, family)
              self.interface_direction("-i")
            end

            def src_ip_list
              to_from.rule.to_list(family)
            end

            def dst_ip_list
              to_from.rule.from_list(family)
            end

            def set_protocols(protocol)
              super(protocol)

              if to_from.rule.connection?
                push_middle("-m state --state RELATED,ESTABLISHED")
              end

              if to_from.rule.get_log
                push_end("--nflog-prefix #{to_from.rule.get_log}#{self.ifname.gsub(/[^a-zA-Z0-9]/,":")}")
              end

              if to_from.rule.get_dports && !to_from.rule.get_dports.empty?
                push_middle("--sports #{to_from.rule.get_dports.join(",")}")
              end

              if to_from.rule.get_sports && !to_from.rule.get_sports.empty?
                push_middle_right("--dports #{to_from.rule.get_sports.join(",")}")
              end

              if to_from.rule.icmp? && to_from.rule.get_type
                state = {
                  Construqt::Firewalls::ICMP::Ping => {
                    Construqt::Addresses::IPV4 => "-m icmp --icmp-type 0/0",
                    Construqt::Addresses::IPV6 => "--icmpv6-type 129",
                  }
                }[to_from.rule.get_type][family]
                throw "state for #{to_from.rule.get_type} #{family}" unless state
                push_middle(state)
              end
            end
          end
        end

        def self.calc_hash_value(direction, _prefix, _list, _end)
          out = []
          _list.each do |ip|
            out << "#{_prefix} #{ip.to_string} -j #{_end}"
          end

          OpenStruct.new(:rows => out, :hmac => Digest::MD5.base64digest(out.join("\n")).gsub(/[^a-zA-Z0-9]/,''))
        end

        def self.write_jump_destination(direction, prefix, list, suffix)
          result = calc_hash_value(direction, prefix, list, suffix)
          # work on these do a better hashing
          unless direction.to_from.section.jump_destinations[result.hmac]
            result.rows.each do |row|
              direction.row(row, result.hmac)
            end

            direction.to_from.section.jump_destinations[result.hmac] = true
          end

          result.hmac
        end

        def self.write_line(direction, src_ip = nil, dest_ip = nil, action_proc = nil)
          src_ip_str = src_ip ? "-s #{src_ip.to_string}" : ""
          dest_ip_str = dest_ip ? "-d #{dest_ip.to_string}" : ""
          action = action_proc.nil? ? "#{direction.action}#{Construqt::Util.space_before(direction.end)}" : action_proc.call
          direction.row("#{direction.ifname}#{Construqt::Util.space_before(direction.begin)}#{Construqt::Util.space_before(src_ip_str)}#{Construqt::Util.space_before(dest_ip_str)}#{Construqt::Util.space_before(direction.middle)} -j #{action}")
        end

        def self.write_table(direction)
          return if direction.family.nil?

          direction.protocols.each do |protocol|
            direction.set_protocols(protocol)
            write_direction(direction)
          end
        end

        def self.write_direction(direction)
          src_list = direction.src_ip_list
          dst_list = direction.dst_ip_list
          # cases
          #
          # to_list.empty? and from_list.empty?
          #
          if src_list.empty? && dst_list.empty?
            write_line(direction, nil, nil)
            return
          end

          #
          # to_list.empty? and not from_list.empty?
          #
          if src_list.empty? && dst_list.length > 0
            dst_list.each do |dest_ip|
              write_line(direction, nil, dest_ip)
            end

            return
          end

          #
          # not to_list.empty? and from_list.empty?
          #
          if src_list.length > 0 && dst_list.empty?
            src_list.each do |src_ip|
              write_line(direction, src_ip, nil)
            end

            return
          end

          #
          # to_list.size == 1 && to_list.size == from_list.size
          #
          if src_list.size == 1 && 1 == dst_list.size
            src_list.each do |src_ip|
              dst_list.each do |dest_ip|
                write_line(direction, src_ip, dest_ip)
              end
            end

            return
          end

          #
          # to_list.size <= from_list.size
          #
          if src_list.size < dst_list.size
            src_list.each do |src_ip|
              action = lambda { write_jump_destination(direction, "-d", dst_list, "#{direction.to_from.rule.get_action}#{Construqt::Util.space_before(direction.end)}") }
              write_line(direction, src_ip, nil, action)
            end

            return
          end

          #
          # from_list.size <= to_list.size
          #
          if src_list.size >= dst_list.size
            dst_list.each do |dest_ip|
              action = lambda { write_jump_destination(direction, "-s", src_list, "#{direction.to_from.rule.get_action}#{Construqt::Util.space_before(direction.end)}") }
              write_line(direction, nil, dest_ip, action)
            end

            return
          end

          throw "UNKNOWN CASE"
        end

        def self.get_rules(fw)
          ret = []
          fw.rules.each do |rule|
            if rule.get_log
              ret << fw.entry!.action("NFLOG").log(rule.get_log)
              rule.log(nil)
            end
            if rule.link_local? && rule.ipv6?
              ret << fw.entry!.action("ACCEPT").icmp.from_is_inside
                .from_my_net.from_net("@ff02::/16@fe80::/64")
                .to_my_net.to_net("@ff02::/16@fe80::/64")
              next
            end
            ret << rule
          end
          ret
        end

        def self.write_raw(fw, raw, ifname, section)
          #        puts ">>>RAW #{iface.name} #{raw.firewall.name}"
          get_rules(raw).each do |rule|
            throw "ACTION must set #{ifname}" unless rule.get_action
            if rule.prerouting?
              to_from = ToFrom.new.(ifname||iface.name, rule, section).request_direction
              write_table(to_from.request_direction()) if rule.request_only?
              write_table(ip_family_v4(fw), rule, to_from.factory(writer.ipv4.prerouting))
              write_table(ip_family_v6(fw), rule, to_from.factory(writer.ipv6.prerouting))
            end

            if rule.output?
              to_from = ToFrom.new.bind_interface(ifname||iface.name, rule, section)
              write_table(ip_family_v4(fw), rule, to_from.factory(writer.ipv4.output))
              write_table(ip_family_v6(fw), rule, to_from.factory(writer.ipv6.output))
            end
          end
        end

        def self.write_nat(fw, nat, ifname, section)
          # nat only for ipv4
          return unless fw.ipv4?

          get_rules(nat).each do |rule|
            throw "ACTION must set #{ifname}" unless rule.get_action
            #throw "TO_SOURCE must set #{ifname}" unless rule.to_source?
            written = false
            rule.postrouting? && rule.get_to_source.each do |src|
              to_from = ToFrom.new(ifname||iface.name, rule, section, section.ipv4.postrouting)
              if rule.from_is_inside?
                direction = to_from.request_direction(Construqt::Addresses::IPV4).push_end("--to-source #{src}")
              else
                direction = to_from.respond_direction(Construqt::Addresses::IPV4).push_end("--to-source #{src}")
              end

              write_table(direction.interface_direction("-o"))
              written = true
            end

            rule.prerouting? && rule.get_to_dest.each do |dst|
              to_from = ToFrom.new(ifname||iface.name, rule, section, section.ipv4.prerouting)
              if rule.from_is_inside?
                direction = to_from.respond_direction(Construqt::Addresses::IPV4).push_end("--to-dest #{dst}")
              else
                direction = to_from.request_direction(Construqt::Addresses::IPV4).push_end("--to-dest #{dst}")
              end

              write_table(direction.interface_direction("-i"))
              written = true
            end

            unless written
              throw "rule doesn't wrote any thing #{rule.block.firewall.name} "+
                "#{iface.name} #{rule.postrouting?} #{rule.get_to_source} "+
                "#{iface.name} #{rule.prerouting?} #{rule.get_to_dest} "
            end
          end
        end

        def self.write_forward(fw, forward, ifname, section)
          get_rules(forward).each do |rule|
            to_from = ToFrom.new(ifname, rule, section)
            write_rule(fw, rule, to_from, section.ipv4.forward, section.ipv6.forward, section.ipv4.forward, section.ipv6.forward)
          end
        end

        def self.write_rule(fw, rule, to_from, ipv4_input, ipv6_input, ipv4_output, ipv6_output)
          #host.add.action(Construqt::Firewalls::Actions::ACCEPT).interface.connection.from_net("#NA-INTERNET").to_host("@1.1.1.1").tcp.dport(22).from_is_outside
          #INPUT REQ -i -s 0.0.0.0 -d 1.1.1.1
          #OUTPUT RES -o -d 0.0.0.0 -s 1.1.1.1

          #host.add.action(Construqt::Firewalls::Actions::ACCEPT).interface.connection.from_net("#NA-INTERNET").to_host("@1.1.1.1").tcp.dport(22).from_is_inside
          #
          #OUTPUT REQ -o -s 0.0.0.0 -d 1.1.1.1
          #INPUT  RES -i -d 0.0.0.0 -s 1.1.1.1

          [{
            :doit    => rule.request_only?,
            :direction => lambda { |family|
              (rule.from_is_outside? ? to_from.request_direction(family) : to_from.respond_direction(family))
                .interface_direction("-i").set_writer(family == Construqt::Addresses::IPV4 ? ipv4_input : ipv6_input)
            }
          },{
            :doit    => rule.respond_only?,
            :direction => lambda { |family|
              (rule.from_is_outside? ? to_from.respond_direction(family) : to_from.request_direction(family))
                .interface_direction("-o").set_writer(family == Construqt::Addresses::IPV4 ? ipv4_output : ipv6_output)
            }
          }].select{|to_from_writer| to_from_writer[:doit] }.each do |to_from_writer|
            {Construqt::Addresses::IPV4 => rule.ipv4?, Construqt::Addresses::IPV6 => rule.ipv6? }.each do |family, enabled|
              next unless enabled
              direction = to_from_writer[:direction].call(family)
              write_table(direction)
            end
          end
        end

        def self.write_host(fw, host, ifname, section)
          get_rules(host).each do |rule|
            to_from = ToFrom.new(ifname, rule, section)
            write_rule(fw, rule, to_from, section.ipv4.input, section.ipv6.input, section.ipv4.output, section.ipv6.output)
          end
        end

        def self.create_from_iface(ifname, iface, writer)
          iface.delegate.firewalls.each do |firewall|
            firewall.get_raw && Firewall.write_raw(firewall, firewall.get_raw, ifname||iface.name, writer.raw)
            firewall.get_nat && Firewall.write_nat(firewall, firewall.get_nat, ifname||iface.name, writer.nat)
            firewall.get_forward && Firewall.write_forward(firewall, firewall.get_forward, ifname||iface.name, writer.filter)
            firewall.get_host && Firewall.write_host(firewall, firewall.get_host, ifname||iface.name, writer.filter)
          end
        end

        def self.create(host, ifname, iface, family)
          throw 'interface must set' unless ifname
          writer = iface.host.result.etc_network_iptables
          create_from_iface(ifname, iface, writer)
          create_from_iface(ifname, iface.delegate.vrrp.delegate.name, writer) if iface.delegate.vrrp
          writer_local = host.result.etc_network_interfaces.get(iface, ifname)
          writer_local.lines.up("iptables-restore < /etc/network/iptables.cfg") if !writer.empty_v4? && (family.nil? || family == Construqt::Addresses::IPV4)
          writer_local.lines.up("ip6tables-restore < /etc/network/ip6tables.cfg") if !writer.empty_v6? && (family.nil? || family == Construqt::Addresses::IPV6)
        end
      end
    end
  end
end
