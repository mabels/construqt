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

          class BeginEndMiddle
            attr_reader :begin, :middle, :end

            def initialize
              @begin = ""
              @middle = ""
              @end = ""
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
          end

          class Direction
            attr_reader :to_from, :family, :to_from, :protocol #, :begin, :end, :middle
            def initialize(to_from, family)
              @to_from = to_from
              @family = family
              @begin_middle_end = BeginEndMiddle.new
            end

            def push_begin(str)
              @begin_middle_end.push_begin(str)
              self
            end
            def push_middle(str)
              @begin_middle_end.push_middle(str)
              self
            end
            def push_end(str)
              @begin_middle_end.push_end(str)
              self
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

            def set_action(action)
              @action = action
              self
            end

            def action
              @action || to_from.rule.get_action
            end

            def row(line, table_name = nil)
              factory = to_from.writer.create
              factory.table(table_name) unless table_name.nil?
              factory.row("#{line}")
            end

            def protocols
              pl = []
              @to_from.rule.get_protocols(@family).each do |proto|
                pl << "-p #{proto}#{Util.space_before(@to_from.rule.get_proto_flags[proto])}"
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

            def create_begin_middle_end(protocol)
              @protocol = @begin_middle_end.clone
              @protocol.push_begin(protocol)
              @protocol
            end
          end

          class RequestDirection < Direction
            def initialize(to_from, family)
              super(to_from, family)
              self.interface_direction("-o")
            end

            def is_not_src_ip?
              to_from.rule.not_from?
            end

            def src_ip_list
              to_from.rule.from_list(family)
            end

            def is_not_dst_ip?
              to_from.rule.not_to?
            end

            def dst_ip_list
              to_from.rule.to_list(family)
            end

            def create_begin_middle_end(protocol)
              begin_middle_end = super(protocol)

              if to_from.rule.get_log
                begin_middle_end.push_end("--nflog-prefix :#{to_from.rule.get_log}#{self.ifname.gsub(/[^a-zA-Z0-9]/,":")}")
              end

              if to_from.rule.respond_to?(:connection?) && to_from.rule.connection?
                begin_middle_end.push_middle("-m conntrack --ctstate NEW,ESTABLISHED")
              end

              unless protocol.include?('icmp')
                if (to_from.rule.get_dports && !to_from.rule.get_dports.empty?) ||
                    (to_from.rule.get_sports && !to_from.rule.get_sports.empty?)
                  begin_middle_end.push_middle("-m multiport")
                end

                if to_from.rule.get_dports && !to_from.rule.get_dports.empty?
                  begin_middle_end.push_middle("--dports #{to_from.rule.get_dports.join(",")}")
                end

                if to_from.rule.get_sports && !to_from.rule.get_sports.empty?
                  begin_middle_end.push_middle("--sports #{to_from.rule.get_sports.join(",")}")
                end
              end

              if protocol.include?('icmp') && to_from.rule.icmp? && to_from.rule.get_type
                state = {
                  Construqt::Firewalls::ICMP::Ping => {
                    Construqt::Addresses::IPV4 => "-m icmp --icmp-type 8/0",
                    Construqt::Addresses::IPV6 => "--icmpv6-type 128",
                  }
                }[to_from.rule.get_type][family]
                throw "state for #{to_from.rule.get_type} #{family}" unless state
                begin_middle_end.push_middle(state)
              end
              begin_middle_end
            end
          end

          class RespondDirection < Direction
            def initialze(to_from, family)
              super(to_from, family)
              self.interface_direction("-i")
            end

            def is_not_src_ip?
              to_from.rule.not_to?
            end

            def src_ip_list
              to_from.rule.to_list(family)
            end

            def is_not_dst_ip?
              to_from.rule.not_from?
            end

            def dst_ip_list
              to_from.rule.from_list(family)
            end

            def create_begin_middle_end(protocol)
              begin_middle_end = super(protocol)

              if to_from.rule.get_log
                begin_middle_end.push_end("--nflog-prefix #{to_from.rule.get_log}#{self.ifname.gsub(/[^a-zA-Z0-9]/,":")}")
              end

              if to_from.rule.respond_to?(:connection?) && to_from.rule.connection?
                begin_middle_end.push_middle("-m conntrack --ctstate RELATED,ESTABLISHED")
              end

              unless protocol.include?('icmp')
                if (to_from.rule.get_dports && !to_from.rule.get_dports.empty?) ||
                    (to_from.rule.get_sports && !to_from.rule.get_sports.empty?)
                  begin_middle_end.push_middle("-m multiport")
                end

                if to_from.rule.get_dports && !to_from.rule.get_dports.empty?
                  begin_middle_end.push_middle("--sports #{to_from.rule.get_dports.join(",")}")
                end

                if to_from.rule.get_sports && !to_from.rule.get_sports.empty?
                  begin_middle_end.push_middle("--dports #{to_from.rule.get_sports.join(",")}")
                end
              end

              if protocol.include?('icmp') && to_from.rule.icmp? && to_from.rule.get_type
                state = {
                  Construqt::Firewalls::ICMP::Ping => {
                    Construqt::Addresses::IPV4 => "-m icmp --icmp-type 0/0",
                    Construqt::Addresses::IPV6 => "--icmpv6-type 129",
                  }
                }[to_from.rule.get_type][family]
                throw "state for #{to_from.rule.get_type} #{family}" unless state
                begin_middle_end.push_middle(state)
              end
              begin_middle_end
            end
          end
        end

        def self.inverse_action(is_not, action)
          unless is_not
            action
          else
            ret = {
              "ACCEPT" => "DROP",
              "DROP" => "ACCEPT"
            }[action]
            throw "action unknown to inverse #{action}" unless ret
            ret
          end
        end
        def self.return_action(is_not, action)
          unless is_not
            "RETURN"
          else
            action
          end
        end

        def self.calc_hash_value(direction, _prefix, is_not, _list, _end)
          out = []
          _list.each_without_missing do |ip|
            out << "#{_prefix} #{ip.to_string} -j #{return_action(!is_not, _end)}"
          end
          out << "-j #{return_action(is_not, _end)}"

          OpenStruct.new(:rows => out, :hmac => Digest::MD5.base64digest(out.join("\n")).gsub(/[^a-zA-Z0-9]/,''))
        end

        def self.write_jump_destination(direction, prefix, is_not, list, suffix)
          result = calc_hash_value(direction, prefix, is_not, list, suffix)
          # work on these do a better hashing
          unless direction.to_from.section.jump_destinations[result.hmac]
            result.rows.each do |row|
              direction.row(row, result.hmac)
            end

            direction.to_from.section.jump_destinations[result.hmac] = true
          end

          result.hmac
        end

        def self.write_line(direction, begin_middle_end, src_ip = nil, dest_ip = nil, action_proc = nil)
          not_src_ip = direction.is_not_src_ip? ? '! ' : ''
          src_ip_str = src_ip ? "#{not_src_ip}-s #{src_ip.to_string}" : ""
          not_dst_ip = direction.is_not_dst_ip? ? '! ' : ''
          dest_ip_str = dest_ip ? "#{not_dst_ip}-d #{dest_ip.to_string}" : ""
          action = action_proc.nil? ? "#{direction.action}#{Construqt::Util.space_before(begin_middle_end.end)}" : action_proc
          direction.row("#{direction.ifname}#{Construqt::Util.space_before(begin_middle_end.begin)}"+
                        "#{Construqt::Util.space_before(src_ip_str)}#{Construqt::Util.space_before(dest_ip_str)}"+
                        "#{Construqt::Util.space_before(begin_middle_end.middle)} -j #{action}")
        end

        def self.write_table(direction)
          return if direction.family.nil?

          direction.protocols.each do |protocol|
            write_direction(direction, direction.create_begin_middle_end(protocol))
          end
        end

        def self.write_direction(direction, begin_middle_end)
          src_list = direction.src_ip_list
          dst_list = direction.dst_ip_list

          # cases
          #
          # to_list.empty? and from_list.empty?
          #
          #
          # to_list.size == 1 && to_list.size == from_list.size
          #
          if (src_list.empty? && dst_list.empty?) or
             (src_list.size_without_missing == 1 && dst_list.size_without_missing == 1)
            write_line(direction, begin_middle_end, src_list.first, dst_list.first)
            return
          end

          #
          #
          # to_list.empty? and not from_list.empty?
          #
          if src_list.empty? && dst_list.size_without_missing > 0
            dst_list.each_without_missing do |dest_ip|
              write_line(direction, begin_middle_end, nil, dest_ip)
            end

            return
          end

          #
          # not to_list.empty? and from_list.empty?
          #
          if src_list.size_without_missing > 0 && dst_list.empty?
            src_list.each_without_missing do |src_ip|
              write_line(direction, begin_middle_end, src_ip, nil)
            end

            return
          end

          if src_list.size_without_missing < 1 || dst_list.size_without_missing < 1
            # one side is atleased missing
            return
          end


          #
          # to_list.size <= from_list.size
          #
          # -j SRC-Target
          # SRC-Target -s A -j DST-Target
          # SRC-Target -s B -j DST-Target
          # SRC-Target -s C -j DST-Target
          # SRC-Target -j RETURN
          # DST-Target -d D -j ACCEPT
          # DST-Target -d E -j ACCEPT
          # DST-Target -d F -j ACCEPT
          # DST-Target -j RETURN
          #
          # -j SRC-Target
          # !SRC-Target -s A -j RETURN
          # !SRC-Target -s B -j RETURN
          # !SRC-Target -s C -j RETURN
          # !SRC-Target -j DST-Target
          # DST-Target -d D -j ACCEPT
          # DST-Target -d E -j ACCEPT
          # DST-Target -d F -j ACCEPT
          # DST-Target -j RETURN
          #
          # -j SRC-Target
          # !SRC-Target -s A -j RETURN
          # !SRC-Target -s B -j RETURN
          # !SRC-Target -s C -j RETURN
          # !SRC-Target -j !DST-Target
          # !DST-Target -d D -j RETURN
          # !DST-Target -d E -j RETURN
          # !DST-Target -d F -j RETURN
          # !DST-Target -j ACCEPT
          #
          if src_list.size_without_missing == 1 && dst_list.size_without_missing > 1
            dst_action = write_jump_destination(direction, "-d", direction.is_not_dst_ip?, dst_list, "#{direction.to_from.rule.get_action}#{Construqt::Util.space_before(begin_middle_end.end)}")
            write_line(direction, begin_middle_end, src_list.first, nil, dst_action)
            return
          end
          if dst_list.size_without_missing == 1 && src_list.size_without_missing > 1
            src_action = write_jump_destination(direction, "-s", direction.is_not_src_ip?, src_list, "#{direction.to_from.rule.get_action}#{Construqt::Util.space_before(begin_middle_end.end)}")
            write_line(direction, begin_middle_end, nil, dst_list.first, src_action)
            return
          end

          if src_list.size_without_missing < dst_list.size_without_missing
            #src_list.each_without_missing do |src_ip|
            dst_action = write_jump_destination(direction, "-d", direction.is_not_dst_ip?, dst_list, "#{direction.to_from.rule.get_action}#{Construqt::Util.space_before(begin_middle_end.end)}")
            src_action = write_jump_destination(direction, "-s", direction.is_not_src_ip?, src_list, dst_action)
            write_line(direction, begin_middle_end, nil, nil, src_action)
            #end

            return
          end

          #
          # from_list.size <= to_list.size
          #
          if src_list.size_without_missing >= dst_list.size_without_missing
            dst_action = write_jump_destination(direction, "-s", direction.is_not_src_ip?, src_list, "#{direction.to_from.rule.get_action}#{Construqt::Util.space_before(begin_middle_end.end)}")
            src_action = write_jump_destination(direction, "-d", direction.is_not_dst_ip?, dst_list, dst_action)
            write_line(direction, begin_middle_end, nil, nil, src_action)

            #dst_list.each_without_missing do |dest_ip|
            #  action = lambda { write_jump_destination(direction, "-s", direction.is_not_src_ip?, src_list, "#{direction.to_from.rule.get_action}#{Construqt::Util.space_before(begin_middle_end.end)}") }
            #  write_line(direction, begin_middle_end, nil, dest_ip, action)
            #end

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

            if rule.respond_to?(:link_local?) && rule.link_local? && rule.ipv6?
              ret << fw.entry!.action("ACCEPT").ipv6.icmp.from_is_inside
                .from_my_net.from_net("@ff02::/16@fe80::/64")
                .to_my_net.to_net("@ff02::/16@fe80::/64")
              next
            end

            if rule.get_action == Construqt::Firewalls::Actions::TCPMSS
              if rule.get_ipv4_mss
                ret << fw.entry!.action("TCPMSS --set-mss #{rule.get_ipv4_mss}")
                    .copy_from_to(rule).ipv4.tcp.proto_flags("tcp", "--tcp-flags SYN,RST SYN")
              else
                ret << fw.entry!.action("TCPMSS --clamp-mss-to-pmtu").copy_from_to(rule).ipv4.tcp.proto_flags("tcp", "--tcp-flags SYN,RST SYN")
              end
              if rule.get_ipv6_mss
                ret << fw.entry!.action("TCPMSS --set-mss #{rule.get_ipv6_mss}").copy_from_to(rule).ipv6.tcp.proto_flags("tcp", "--tcp-flags SYN,RST SYN")
              else
                ret << fw.entry!.action("TCPMSS --clamp-mss-to-pmtu").copy_from_to(rule).ipv6.tcp.proto_flags("tcp", "--tcp-flags SYN,RST SYN")
              end
              next
            end

            ret << rule
          end

          ret
        end

        def self.write_raw(fw, raw, ifname, section)
          #        puts ">>>RAW #{iface.name} #{raw.firewall.name}"
          get_rules(raw).each do |rule|
            {
              Construqt::Addresses::IPV4 => {
                :enabled => rule.ipv4?,
                :prerouting => section.ipv4.prerouting,
                :output => section.ipv4.output
              },
              Construqt::Addresses::IPV6 => {
                :enabled => rule.ipv6?,
                :prerouting => section.ipv6.prerouting,
                :output => section.ipv6.output
              }
            }.each do |family, cfg|
              next unless cfg[:enabled]
              to_from = ToFrom.new(ifname, rule, section)
              if rule.prerouting?
                write_table(to_from.request_direction(family).set_writer(cfg[:prerouting]).interface_direction("-i"))
              end

              if rule.output?
                write_table(to_from.respond_direction(family).set_writer(cfg[:output]).interface_direction("-o"))
              end
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
            if rule.postrouting?
              rule.get_to_source.each do |src|
                to_from = ToFrom.new(ifname||iface.name, rule, section, section.ipv4.postrouting)
                if rule.from_is_inside?
                  direction = to_from.request_direction(Construqt::Addresses::IPV4).push_end("--to-source #{src}")
                else
                  direction = to_from.respond_direction(Construqt::Addresses::IPV4).push_end("--to-source #{src}")
                end

                write_table(direction.interface_direction("-o"))
                written = true
              end
              if rule.get_to_source.empty?
                to_from = ToFrom.new(ifname||iface.name, rule, section, section.ipv4.postrouting)
                if rule.from_is_inside?
                  direction = to_from.request_direction(Construqt::Addresses::IPV4).set_action("MASQUERADE")
                else
                  direction = to_from.respond_direction(Construqt::Addresses::IPV4).set_action("MASQUERADE")
                end
                write_table(direction.interface_direction("-o"))
                written = true
              end
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
              Construqt.logger.warn "rule doesn't wrote any thing #{rule.block.firewall.name} "+
                "#{ifname} #{rule.postrouting?} #{rule.get_to_source} "+
                "#{ifname} #{rule.prerouting?} #{rule.get_to_dest} "
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
          create_from_iface(ifname, iface.delegate.vrrp.delegate, writer) if iface.delegate.vrrp
          writer_local = host.result.etc_network_interfaces.get(iface, ifname)
          writer_local.lines.up("iptables-restore < /etc/network/iptables.cfg") if !writer.empty_v4? && (family.nil? || family == Construqt::Addresses::IPV4)
          writer_local.lines.up("ip6tables-restore < /etc/network/ip6tables.cfg") if !writer.empty_v6? && (family.nil? || family == Construqt::Addresses::IPV6)
        end
      end
    end
  end
end
