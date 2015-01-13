module Construqt
  module Flavour
    module Ubuntu

      module Firewall
        class ToFrom
          include Util::Chainable
          chainable_attr_value :begin, nil
          chainable_attr_value :begin_to, nil
          chainable_attr_value :begin_from, nil
          chainable_attr_value :middle, nil
          chainable_attr_value :middle_to, nil
          chainable_attr_value :middle_from, nil
          chainable_attr_value :end, nil
          chainable_attr_value :end_to, nil
          chainable_attr_value :end_from, nil
          chainable_attr_value :factory, nil
          chainable_attr_value :ifname, nil
          chainable_attr_value :interface, nil
          chainable_attr_value :output_ifname_direction, "-i"
          chainable_attr_value :input_ifname_direction, "-o"


          def output_only
            @input_only = false
            @output_only = true
            self
          end

          def output_only?
            defined?(@output_only) ? @output_only : true
          end

          def input_only
            @input_only = true
            @output_only = false
            self
          end

          def input_only?
            defined?(@input_only) ? @input_only : true
          end

          def assign_in_out(rule)
            @output_only = rule.output_only?
            @input_only = rule.input_only?
            self
          end

          def space_before(str)
            if str.nil? or str.empty?
              ""
            else
              " "+str.strip
            end
          end

          def push_begin_to(str)
            begin_to(get_begin_to + space_before(str))
          end

          def push_begin_from(str)
            begin_from(get_begin_from + space_before(str))
          end

          def push_middle_to(str)
            middle_to(get_middle_to + space_before(str))
          end

          def push_middle_from(str)
            middle_from(get_middle_from + space_before(str))
          end

          def push_end_to(str)
            end_to(get_end_to + space_before(str))
          end

          def push_end_from(str)
            end_from(get_end_from + space_before(str))
          end

          def get_begin_to
            return space_before(@begin_to) if @begin_to
            return space_before(@begin)
          end

          def get_begin_from
            return space_before(@begin_from) if @begin_from
            return space_before(@begin)
          end

          def get_middle_to
            return space_before(@middle_to) if @middle_to
            return space_before(@middle)
          end

          def get_middle_from
            return space_before(@middle_from) if @middle_from
            return space_before(@middle)
          end

          def get_end_to
            return space_before(@end_to) if @end_to
            return space_before(@end)
          end

          def get_end_from
            return space_before(@end_from) if @end_from
            return space_before(@end)
          end

          def bind_section(section)
            @section = section
            self
          end

          def section
            @section
          end

          def bind_interface(ifname, iface, rule)
            self.interface(iface)
            self.ifname(ifname)
            if rule.from_is_inbound?
              output_ifname_direction("-i")
              input_ifname_direction("-o")
            else
              output_ifname_direction("-o")
              input_ifname_direction("-i")
            end
          end

          def output_ifname
            return space_before("#{@output_ifname_direction} #{@ifname}") if @ifname
            return ""
          end

          def input_ifname
            return space_before("#{@input_ifname_direction} #{@ifname}") if @ifname
            return ""
          end

          def has_to?
            @begin || @begin_to || @middle || @middle_to || @end || @end_to
          end

          def has_from?
            @begin || @begin_from || @middle || @middle_from || @end || @end_from
          end

          def create_row
            get_factory.create
          end
        end

        def self.ip_family_v4(fw)
          return Construqt::Addresses::IPV4 if fw.ipv4?
          nil
        end

        def self.ip_family_v6(fw)
          return Construqt::Addresses::IPV6 if fw.ipv6?
          nil
        end

        def self.calc_hash_value(_prefix, _list, _end, to_from, rule)
          out = []
          _list.each do |ip|
            out << "#{_prefix} #{ip.to_string} -j #{rule.get_action}#{_end}"
          end
          OpenStruct.new(:rows => out, :hmac => Digest::MD5.base64digest(out.join("\n")).gsub(/[^a-zA-Z0-9]/,''))
        end

        def self.write_jump_destination(_prefix, _list, _end, to_from, rule)
          result = calc_hash_value(_prefix, _list, _end, to_from, rule)
          # work on these do a better hashing
          unless to_from.section.jump_destinations[result.hmac]
            result.rows.each do |row|
              to_from.create_row.table(result.hmac).row(row)
            end
            to_from.section.jump_destinations[result.hmac] = true
          end
          result.hmac
        end

        def self.write_table(family, rule, to_from)
          return if family.nil?
          return unless (family == Construqt::Addresses::IPV4 && rule.ipv4?) || (family == Construqt::Addresses::IPV6 && rule.ipv6?)

          from_list = rule.from_list(family)
          to_list = rule.to_list(family)
          action_i = action_o = rule.get_action

          # cases
          #
          # to_list.empty? and from_list.empty?
          #
          if to_list.empty? && from_list.empty?
            if to_from.output_only?
              to_from.create_row.row("#{to_from.output_ifname}#{to_from.get_begin_from}#{to_from.get_middle_to} -j #{rule.get_action}#{to_from.get_end_to}")
            end

            if to_from.input_only?
              to_from.create_row.row("#{to_from.input_ifname}#{to_from.get_begin_to}#{to_from.get_middle_from} -j #{rule.get_action}#{to_from.get_end_from}")
            end

            return
          end

          #
          # to_list.empty? and not from_list.empty?
          #
          if to_list.empty? && from_list.length > 0
            from_list.each do |ip|
              if to_from.output_only?
                to_from.create_row.row("#{to_from.output_ifname}#{to_from.get_begin_from} -s #{ip.to_string}#{to_from.get_middle_from} -j #{action_o}#{to_from.get_end_to}")
              end

              if to_from.input_only?
                to_from.create_row.row("#{to_from.input_ifname}#{to_from.get_begin_to} -d #{ip.to_string}#{to_from.get_middle_to} -j #{action_i}#{to_from.get_end_from}")
              end
            end

            return
          end

          #
          # not to_list.empty? and from_list.empty?
          #
          if to_list.length > 0 && from_list.empty?
            to_list.each do |ip|
              if to_from.output_only?
                to_from.create_row.row("#{to_from.output_ifname}#{to_from.get_begin_from} -s #{ip.to_string}#{to_from.get_middle_from} -j #{action_o}#{to_from.get_end_to}")
              end

              if to_from.input_only?
                to_from.create_row.row("#{to_from.input_ifname}#{to_from.get_begin_to} -d #{ip.to_string}#{to_from.get_middle_to} -j #{action_i}#{to_from.get_end_from}")
              end
            end

            return
          end

          #
          # to_list.size == 1 && to_list.size == from_list.size
          #
          if to_list.size == 1 && to_list.size == from_list.size
            from_list.each do |from_ip|
              to_list.each do |to_ip|
                if to_from.output_only?
                  to_from.create_row.row("#{to_from.output_ifname}#{to_from.get_begin_from} -s #{from_ip.to_string} -d #{to_ip.to_string}#{to_from.get_middle_from} -j #{action_o}#{to_from.get_end_to}")
                end

                if to_from.input_only?
                  to_from.create_row.row("#{to_from.input_ifname}#{to_from.get_begin_to} -d #{from_ip.to_string} -s #{to_ip.to_string}#{to_from.get_middle_to} -j #{action_i}#{to_from.get_end_from}")
                end
              end
            end
            return
          end

          #
          # to_list.size <= from_list.size
          #
          if to_list.size < from_list.size
            to_list.each do |to_ip|
              if to_from.output_only?
                action = write_jump_destination("-s", from_list, to_from.get_end_to, to_from, rule)
                to_from.create_row.row("#{to_from.output_ifname}#{to_from.get_begin_from} -d #{to_ip.to_string}#{to_from.get_middle_from} -j #{action}")
              end

              if to_from.input_only?
                action = write_jump_destination("-d", from_list, to_from.get_end_to, to_from, rule)
                to_from.create_row.row("#{to_from.input_ifname}#{to_from.get_begin_to} -s #{to_ip.to_string}#{to_from.get_middle_to} -j #{action}")
              end
            end
            return
          end
          #
          # from_list.size <= to_list.size
          #
          if from_list.size <= to_list.size
            from_list.each do |from_ip|
              if to_from.output_only?
                action = write_jump_destination("-d", to_list, to_from.get_end_from, to_from, rule)
                to_from.create_row.row("#{to_from.output_ifname}#{to_from.get_begin_from} -s #{from_ip.to_string}#{to_from.get_middle_from} -j #{action}")
              end

              if to_from.input_only?
                action = write_jump_destination("-s", to_list, to_from.get_end_from, to_from, rule)
                to_from.create_row.row("#{to_from.input_ifname}#{to_from.get_begin_to} -d #{from_ip.to_string}#{to_from.get_middle_to} -j #{action}")
              end
            end
            return
          end

          throw "UNKNOWN CASE"
        end

        def self.write_raw(fw, raw, ifname, iface, writer)
          #        puts ">>>RAW #{iface.name} #{raw.firewall.name}"
          raw.rules.each do |rule|
            throw "ACTION must set #{ifname}" unless rule.get_action
            if rule.prerouting?
              to_from = ToFrom.new.bind_interface(ifname, iface, rule).bind_section(writer).assign_in_out(rule)
              #puts "PREROUTING #{to_from.inspect}"
              write_table(ip_family_v4(fw), rule, to_from.factory(writer.ipv4.prerouting))
              write_table(ip_family_v6(fw), rule, to_from.factory(writer.ipv6.prerouting))
            end

            if rule.output?
              to_from = ToFrom.new.bind_interface(ifname, iface, rule).bind_section(writer).assign_in_out(rule)
              write_table(ip_family_v4(fw), rule, to_from.factory(writer.ipv4.output))
              write_table(ip_family_v6(fw), rule, to_from.factory(writer.ipv6.output))
            end
          end
        end

        def self.write_nat(fw, nat, ifname, iface, writer)
          # nat only for ipv4
          return unless fw.ipv4?

          nat.rules.each do |rule|
            throw "ACTION must set #{ifname}" unless rule.get_action
            #throw "TO_SOURCE must set #{ifname}" unless rule.to_source?
            written = false
            rule.postrouting? && rule.get_to_source.each do |src|
              to_from = ToFrom.new.bind_interface(ifname, iface, rule).bind_section(writer).assign_in_out(rule).end_to("--to-source #{src}")
                .ifname(ifname).factory(writer.ipv4.postrouting)
              protocol_loop(Construqt::Addresses::IPV4, rule).each do |protocol|
                self.set_port_protocols(protocol, Construqt::Addresses::IPV4, rule, to_from)
                write_table(Construqt::Addresses::IPV4, rule, to_from)
                written = true
              end
            end

            rule.prerouting? && rule.get_to_dest.each do |dst|
              #binding.pry
              to_from = ToFrom.new.bind_interface(ifname, iface, rule).bind_section(writer).assign_in_out(rule).end_from("--to-dest #{dst}")
                .ifname(ifname).factory(writer.ipv4.prerouting)
              protocol_loop(Construqt::Addresses::IPV4, rule).each do |protocol|
                self.set_port_protocols(protocol, Construqt::Addresses::IPV4, rule, to_from)
                write_table(Construqt::Addresses::IPV4, rule, to_from)
                written = true
              end
            end

            unless written
              throw "rule doesn't wrote any thing #{rule.block.firewall.name} "+
                "#{iface.name} #{rule.postrouting?} #{rule.get_to_source} "+
                "#{iface.name} #{rule.prerouting?} #{rule.get_to_dest} "
            end
          end
        end

        def self.protocol_loop(family, rule)
          pl = []
          rule.get_protocols(family).each do |proto|
            pl << "-p #{proto}"
          end

          pl << '' if pl.empty?
          pl
        end

        def self.icmp_type(family, type)
          {
            Construqt::Firewalls::ICMP::PingRequest => {
              :v4 => "-m icmp --icmp-type 8/0",
              :v6 => "--icmpv6-type 128"
            }
          }[type][family]
        end

        def self.write_forward(fw, forward, ifname, iface, writer)
          forward.rules.each do |rule|
            throw "ACTION must set #{ifname}" unless rule.get_action
            #puts "write_forward #{rule.inspect} #{rule.input_only?} #{rule.output_only?}"
            if rule.get_log
              to_from = ToFrom.new.bind_interface(ifname, iface, rule).bind_section(writer).assign_in_out(rule)
                .end_to("--nflog-prefix o:#{rule.get_log}:#{ifname}")
                .end_from("--nflog-prefix i:#{rule.get_log}:#{ifname}")
              write_table(ip_family_v4(fw), rule.clone.action("NFLOG"), to_from.factory(writer.ipv4.forward))
              write_table(ip_family_v6(fw), rule.clone.action("NFLOG"), to_from.factory(writer.ipv6.forward))
            end

            {Construqt::Addresses::IPV4 => { :enabled => fw.ipv4?, :writer => writer.ipv4.forward },
             Construqt::Addresses::IPV6 => { :enabled => fw.ipv6?, :writer => writer.ipv6.forward }}.each do |family, cfg|
              next unless cfg[:enabled]
              to_from = ToFrom.new.bind_interface(ifname, iface, rule).bind_section(writer).assign_in_out(rule)

              protocol_loop(family, rule).each do |protocol|
                self.set_port_protocols(protocol, family, rule, to_from)

                if rule.icmp? && rule.get_type
                  to_from.push_middle_from(icmp_type(family, rule.get_type))
                end

                if rule.connection?
                  to_from.push_middle_from("-m state --state NEW,ESTABLISHED")
                  to_from.push_middle_to("-m state --state RELATED,ESTABLISHED")
                end

                write_table(family, rule, to_from.factory(cfg[:writer]))
              end
            end
          end
        end

        def self.create_link_local(fw, ifname, iface, rule, writer)
          return unless fw.ipv6?
          # fe80::/64
          # ff02::/16 dest
          i_to_from = ToFrom.new.bind_interface(ifname, iface, rule).bind_section(writer).input_only
          i_rule = rule.clone.from_my_net.to_my_net
          i_to_from.push_begin_to("-p icmpv6")
          i_rule.to_net("#fe80::/64")
          i_rule.from_net("@ff02::/16@fe80::/64")
          write_table(ip_family_v6(fw), i_rule, i_to_from.factory(writer.ipv6.input))

          #i_to_from = ToFrom.new.bind_interface(ifname, iface, rule).input_only
          #i_rule = rule.clone.from_my_net.to_my_net
          #i_to_from.push_begin_to("-p icmpv6")
          #i_rule.to_net_addr("fe80::/64")
          #i_rule.from_net_addr("fe80::/64")
          #i_to_from.push_middle_to("--icmpv6-type 136")
          #write_table("ip6tables", i_rule, i_to_from.factory(writer.ipv6.input))

          o_to_from = ToFrom.new.bind_interface(ifname, iface, rule).bind_section(writer).output_only
          o_to_from.push_begin_from("-p icmpv6")
          o_rule = rule.clone.from_my_net.to_my_net
          #o_rule.from_net_addr("fe80::/64")
          o_rule.from_net("@fe80::/64")
          o_rule.to_net("@ff02::/16@fe80::/64")
          #o_to_from.push_middle_from("--icmpv6-type 135")
          write_table(ip_family_v6(fw), o_rule, o_to_from.factory(writer.ipv6.output))

          #binding.pry
          #o_to_from = ToFrom.new.bind_interface(ifname, iface, rule).output_only
          #o_to_from.push_begin_from("-p icmpv6")
          #o_rule = rule.clone.from_my_net.to_my_net
          #o_rule.from_net_addr("fe80::/64")
          #o_rule.to_net_addr("fe80::/64")
          #o_to_from.push_middle_from("--icmpv6-type 136")
          #write_table("ip6tables", o_rule, o_to_from.factory(writer.ipv6.output))
        end

        def self.set_port_protocols(protocol, family, rule, to_from)
          to_from.push_begin_to(protocol)
          to_from.push_begin_from(protocol)

          if (rule.get_dports && !rule.get_dports.empty?) ||
             (rule.get_sports && !rule.get_sports.empty?)
            to_from.push_middle_from("-m multiport")
            to_from.push_middle_to("-m multiport")
          end

          if rule.get_dports && !rule.get_dports.empty?
            to_from.push_middle_from("--dports #{rule.get_dports.join(",")}")
            to_from.push_middle_to("--sports #{rule.get_dports.join(",")}")
          end


          if rule.get_sports && !rule.get_sports.empty?
            to_from.push_middle_from("--sports #{rule.get_sports.join(",")}")
            to_from.push_middle_to("--dports #{rule.get_sports.join(",")}")
          end

          if rule.icmp? && rule.get_type
            to_from.push_middle_from(icmp_type(family, rule.get_type))
          end
        end

        def self.write_host(fw, host, ifname, iface, writer)
          host.rules.each do |rule|
            if rule.get_log
              #binding.pry if iface.host.name == "admin-gw" and ifname == "v997"
              nflog_rule = rule.clone.action("NFLOG")
              l_in_to_from = ToFrom.new.bind_interface(ifname, iface, nflog_rule).bind_section(writer).input_only
                .end_from("--nflog-prefix o:#{rule.get_log}:#{ifname}")
              l_out_to_from = ToFrom.new.bind_interface(ifname, iface, nflog_rule).bind_section(writer).output_only
                .end_to("--nflog-prefix i:#{rule.get_log}:#{ifname}")
              write_table(ip_family_v4(fw), nflog_rule, l_in_to_from.factory(writer.ipv4.input))
              write_table(ip_family_v4(fw), nflog_rule, l_out_to_from.factory(writer.ipv4.output))
              write_table(ip_family_v6(fw), nflog_rule, l_in_to_from.factory(writer.ipv6.input))
              write_table(ip_family_v6(fw), nflog_rule, l_out_to_from.factory(writer.ipv6.output))
            end

            next create_link_local(fw, ifname, iface, rule, writer) if rule.link_local?

            [{
              :doit    => rule.input_only?,
              :from_to => lambda { ToFrom.new.bind_interface(ifname, iface, rule).bind_section(writer).input_only },
              :writer4 => !rule.from_is_inbound? ? writer.ipv4.input : writer.ipv4.output,
              :writer6 => !rule.from_is_inbound? ? writer.ipv6.input : writer.ipv6.output
            },{
              :doit    => rule.output_only?,
              :from_to => lambda { ToFrom.new.bind_interface(ifname, iface, rule).bind_section(writer).output_only },
              :writer4 => rule.from_is_inbound? ? writer.ipv4.input : writer.ipv4.output,
              :writer6 => rule.from_is_inbound? ? writer.ipv6.input : writer.ipv6.output
            }].each do |to_from_writer|
              next unless to_from_writer[:doit]
              {Construqt::Addresses::IPV4 => { :enabled => fw.ipv4?, :writer => to_from_writer[:writer4]},
               Construqt::Addresses::IPV6 => { :enabled => fw.ipv6?, :writer => to_from_writer[:writer6] }}.each do |family, cfg|
                to_from = to_from_writer[:from_to].call
                next unless cfg[:enabled]

                protocol_loop(family, rule).each do |protocol|
                  self.set_port_protocols(protocol, family, rule, to_from)
                  if rule.connection?
                    to_from.push_middle_from("-m state --state NEW,ESTABLISHED")
                    to_from.push_middle_to("-m state --state RELATED,ESTABLISHED")
                  end

                  write_table(family, rule, to_from.factory(cfg[:writer]))
                end
              end
            end
          end
        end

        def self.create_from_iface(ifname, iface, writer)
          iface.delegate.firewalls.each do |firewall|
            firewall.get_raw && Firewall.write_raw(firewall, firewall.get_raw, ifname, iface, writer.raw)
            firewall.get_nat && Firewall.write_nat(firewall, firewall.get_nat, ifname, iface, writer.nat)
            firewall.get_forward && Firewall.write_forward(firewall, firewall.get_forward, ifname, iface, writer.filter)
            firewall.get_host && Firewall.write_host(firewall, firewall.get_host, ifname, iface, writer.filter)
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
