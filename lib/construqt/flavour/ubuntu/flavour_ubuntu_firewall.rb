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
          chainable_attr :output_only, true, false
          chainable_attr :input_only, true, false
          chainable_attr_value :output_ifname_direction, "-i"
          chainable_attr_value :input_ifname_direction, "-o"

          def assign_in_out(rule)
            output_only if rule.output_only?
            input_only if rule.input_only?
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

          def factory!
            get_factory.create
          end
        end


        def self.filter_routes(routes, family)
          routes.map{|i| i.dst }.select{|i| family == Construqt::Addresses::IPV6 ? i.ipv6? : i.ipv4? }
        end

        def self.write_table(iptables, rule, to_from)
          family = iptables=="ip6tables" ? Construqt::Addresses::IPV6 : Construqt::Addresses::IPV4
          if rule.from_my_net?
            networks = iptables=="ip6tables" ? to_from.get_interface.address.v6s : to_from.get_interface.address.v4s
            if rule.from_route?
              networks += self.filter_routes(to_from.get_interface.address.routes, family)
            end
            from_list = IPAddress.summarize(networks)
          else
            from_list = Construqt::Tags.ips_net(rule.get_from_net, family)
          end

          if rule.to_my_net?
            networks = iptables=="ip6tables" ? to_from.get_interface.address.v6s : to_from.get_interface.address.v4s
            if rule.from_route?
              networks += self.filter_routes(to_from.get_interface.address.routes, family)
            end
            to_list = IPAddress.summarize(networks)
          else
            if rule.get_to_host
              to_list = Construqt::Tags.ips_hosts(rule.get_to_host, family)
            else
              to_list = Construqt::Tags.ips_net(rule.get_to_net, family)
            end
          end
          unless rule.get_to_net_addr.empty?
            addrs = rule.get_to_net_addr.map { |i| IPAddress.parse(i) }.select { |i|
              (i.ipv6? && family == Construqt::Addresses::IPV6) || (i.ipv4? && family == Construqt::Addresses::IPV4)
            }
            to_list = IPAddress.summarize(to_list + addrs)
          end
          unless rule.get_from_net_addr.empty?
            addrs = rule.get_from_net_addr.map { |i| IPAddress.parse(i) }.select { |i|
              (i.ipv6? && family == Construqt::Addresses::IPV6) || (i.ipv4? && family == Construqt::Addresses::IPV4)
            }
            from_list = IPAddress.summarize(from_list + addrs)
          end
          #puts ">>>>>#{from_list.inspect}"
          #puts ">>>>>#{state.inspect} end_to:#{state.end_to}:#{state.end_from}:#{state.middle_to}#{state.middle_from}"
          action_i = action_o = rule.get_action
          if to_list.empty? && from_list.empty?
            #puts "write_table=>o:#{to_from.output_only?}:#{to_from.output_ifname} i:#{to_from.input_only?}:#{to_from.input_ifname}"
            if to_from.output_only?
              to_from.factory!.row("#{to_from.output_ifname}#{to_from.get_begin_from}#{to_from.get_middle_to} -j #{rule.get_action}#{to_from.get_end_to}")
            end

            if to_from.input_only?
              to_from.factory!.row("#{to_from.input_ifname}#{to_from.get_begin_to}#{to_from.get_middle_from} -j #{rule.get_action}#{to_from.get_end_from}")
            end
          end

          if to_list.length > 1
            # work on these do a better hashing
            action_o = "I.#{to_from.get_ifname}.#{rule.object_id.to_s(32)}"
            action_i = "O.#{to_from.get_ifname}.#{rule.object_id.to_s(32)}"
            to_list.each do |ip|
              if to_from.output_only?
                to_from.factory!.table(action_o).row("#{to_from.output_ifname} -d #{ip.to_string} -j #{rule.get_action}")
              end

              if to_from.input_only?
                to_from.factory!.table(action_i).row("#{to_from.input_ifname} -s #{ip.to_string} -j #{rule.get_action}")
              end
            end

          elsif to_list.length == 1
            from_dst = " -d #{to_list.first.to_string}"
            to_src = " -s #{to_list.first.to_string}"
          else
            from_dst = to_src =""
          end

          from_list.each do |ip|
            if to_from.output_only?
              to_from.factory!.row("#{to_from.output_ifname}#{to_from.get_begin_from} -s #{ip.to_string}#{from_dst}#{to_from.get_middle_from} -j #{action_o}#{to_from.get_end_to}")
            end

            if to_from.input_only?
              to_from.factory!.row("#{to_from.input_ifname}#{to_from.get_begin_to}#{to_src} -d #{ip.to_string}#{to_from.get_middle_to} -j #{action_i}#{to_from.get_end_from}")
            end
          end
        end

        def self.write_raw(fw, raw, ifname, iface, writer)
          #        puts ">>>RAW #{iface.name} #{raw.firewall.name}"
          raw.rules.each do |rule|
            throw "ACTION must set #{ifname}" unless rule.get_action
            if rule.prerouting?
              to_from = ToFrom.new.bind_interface(ifname, iface, rule).assign_in_out(rule)
              #puts "PREROUTING #{to_from.inspect}"
              fw.ipv4? && write_table("iptables", rule, to_from.factory(writer.ipv4.prerouting))
              fw.ipv6? && write_table("ip6tables", rule, to_from.factory(writer.ipv6.prerouting))
            end

            if rule.output?
              to_from = ToFrom.new.bind_interface(ifname, iface, rule).assign_in_out(rule)
              fw.ipv4? && write_table("iptables", rule, to_from.factory(writer.ipv4.output))
              fw.ipv6? && write_table("ip6tables", rule, to_from.factory(writer.ipv6.output))
            end
          end
        end

        def self.write_nat(fw, nat, ifname, iface, writer)
          nat.rules.each do |rule|
            throw "ACTION must set #{ifname}" unless rule.get_action
            throw "TO_SOURCE must set #{ifname}" unless rule.to_source?
            if rule.to_source? && rule.postrouting?
              src = iface.address.ips.select{|ip| ip.ipv4?}.first
              throw "missing ipv4 address and postrouting and to_source is used #{ifname}" unless src
              to_from = ToFrom.new.bind_interface(ifname, iface, rule).assign_in_out(rule).end_to("--to-source #{src}")
                .ifname(ifname).factory(writer.ipv4.postrouting)
              fw.ipv4? && write_table("iptables", rule, to_from)
            end
          end
        end

        def self.protocol_loop(rule)
          protocol_loop = []
          {
            'tcp' => rule.tcp?,
            'udp' => rule.udp?,
            'esp' => rule.esp?,
            'ah' => rule.ah?,
            'icmp' => rule.icmp?
          }.each do |proto, enabled|
            protocol_loop << "-p #{proto}" if enabled
          end
          protocol_loop = [''] if protocol_loop.empty?
          protocol_loop
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
              to_from = ToFrom.new.bind_interface(ifname, iface, rule).assign_in_out(rule)
                .end_to("--nflog-prefix o:#{rule.get_log}:#{ifname}")
                .end_from("--nflog-prefix i:#{rule.get_log}:#{ifname}")
              fw.ipv4? && write_table("iptables", rule.clone.action("NFLOG"), to_from.factory(writer.ipv4.forward))
              fw.ipv6? && write_table("ip6tables", rule.clone.action("NFLOG"), to_from.factory(writer.ipv6.forward))
            end

            protocol_loop(rule).each do |protocol|
              {:v4 => { :enabled => fw.ipv4?, :table => "iptables", :writer => writer.ipv4.forward },
               :v6 => { :enabled => fw.ipv6?, :table => "ip6tables", :writer => writer.ipv6.forward }}.each do |family, cfg|
                next unless cfg[:enabled]
                to_from = ToFrom.new.bind_interface(ifname, iface, rule).assign_in_out(rule)
                if protocol == "-p icmp" && family == :v6
                  my_protocol = "-p icmpv6"
                else
                  my_protocol = protocol
                end
                to_from.push_begin_to(my_protocol)
                to_from.push_begin_from(my_protocol)

                if rule.get_ports && !rule.get_ports.empty?
                  to_from.push_middle_from("-m multiport --dports #{rule.get_ports.join(",")}")
                  to_from.push_middle_to("-m multiport --sports #{rule.get_ports.join(",")}")
                end
                if rule.icmp? && rule.get_type
                  to_from.push_middle_from(icmp_type(family, rule.get_type))
                end

                if rule.connection?
                  to_from.push_middle_from("-m state --state NEW,ESTABLISHED")
                  to_from.push_middle_to("-m state --state RELATED,ESTABLISHED")
                end
                write_table(cfg[:table], rule, to_from.factory(cfg[:writer]))
              end
            end
          end
        end

        def self.create_link_local(fw, ifname, iface, rule, writer)
          return unless fw.ipv6?
          # fe80::/64
          # ff02::/16 dest
          i_to_from = ToFrom.new.bind_interface(ifname, iface, rule).input_only
          i_rule = rule.clone.from_my_net.to_my_net
          i_to_from.push_begin_to("-p icmpv6")
          i_rule.to_net_addr("fe80::/64")
          i_rule.from_net_addr("ff02::/16", "fe80::/64")
          write_table("ip6tables", i_rule, i_to_from.factory(writer.ipv6.input))

          #i_to_from = ToFrom.new.bind_interface(ifname, iface, rule).input_only
          #i_rule = rule.clone.from_my_net.to_my_net
          #i_to_from.push_begin_to("-p icmpv6")
          #i_rule.to_net_addr("fe80::/64")
          #i_rule.from_net_addr("fe80::/64")
          #i_to_from.push_middle_to("--icmpv6-type 136")
          #write_table("ip6tables", i_rule, i_to_from.factory(writer.ipv6.input))

          o_to_from = ToFrom.new.bind_interface(ifname, iface, rule).output_only
          o_to_from.push_begin_from("-p icmpv6")
          o_rule = rule.clone.from_my_net.to_my_net
          #o_rule.from_net_addr("fe80::/64")
          o_rule.from_net_addr("fe80::/64")
          o_rule.to_net_addr("ff02::/16", "fe80::/64")
          #o_to_from.push_middle_from("--icmpv6-type 135")
          write_table("ip6tables", o_rule, o_to_from.factory(writer.ipv6.output))

          #binding.pry
          #o_to_from = ToFrom.new.bind_interface(ifname, iface, rule).output_only
          #o_to_from.push_begin_from("-p icmpv6")
          #o_rule = rule.clone.from_my_net.to_my_net
          #o_rule.from_net_addr("fe80::/64")
          #o_rule.to_net_addr("fe80::/64")
          #o_to_from.push_middle_from("--icmpv6-type 136")
          #write_table("ip6tables", o_rule, o_to_from.factory(writer.ipv6.output))
        end

        def self.write_host(fw, host, ifname, iface, writer)
          host.rules.each do |rule|
            if rule.get_log
              nflog_rule = rule.clone.action("NFLOG")
              l_in_to_from = ToFrom.new.bind_interface(ifname, iface, nflog_rule).input_only
                .end_from("--nflog-prefix o:#{rule.get_log}:#{ifname}")
              l_out_to_from = ToFrom.new.bind_interface(ifname, iface, nflog_rule).output_only
                .end_to("--nflog-prefix i:#{rule.get_log}:#{ifname}")
              fw.ipv4? && write_table("iptables", nflog_rule, l_in_to_from.factory(writer.ipv4.input))
              fw.ipv4? && write_table("iptables", nflog_rule, l_out_to_from.factory(writer.ipv4.output))
              fw.ipv6? && write_table("ip6tables", nflog_rule, l_in_to_from.factory(writer.ipv6.input))
              fw.ipv6? && write_table("ip6tables", nflog_rule, l_out_to_from.factory(writer.ipv6.output))
            end
            next create_link_local(fw, ifname, iface, rule, writer) if rule.link_local?

            protocol_loop(rule).each do |protocol|
              [{
                :from_to => lambda { ToFrom.new.bind_interface(ifname, iface, rule).input_only },
                :writer4 => !rule.from_is_inbound? ? writer.ipv4.input : writer.ipv4.output,
                :writer6 => !rule.from_is_inbound? ? writer.ipv6.input : writer.ipv6.output
              },{
                :from_to => lambda { ToFrom.new.bind_interface(ifname, iface, rule).output_only },
                :writer4 => rule.from_is_inbound? ? writer.ipv4.input : writer.ipv4.output,
                :writer6 => rule.from_is_inbound? ? writer.ipv6.input : writer.ipv6.output
              }].each do |to_from_writer|
                {:v4 => { :enabled => fw.ipv4?, :table => "iptables", :writer => to_from_writer[:writer4]},
                 :v6 => { :enabled => fw.ipv6?, :table => "ip6tables", :writer => to_from_writer[:writer6] }}.each do |family, cfg|
                  to_from = to_from_writer[:from_to].call
                  next unless cfg[:enabled]



                  if protocol == "-p icmp" && family == :v6
                    my_protocol = "-p icmpv6"
                  else
                    my_protocol = protocol
                  end
                  to_from.push_begin_to(my_protocol)
                  to_from.push_begin_from(my_protocol)
                  if rule.get_ports && !rule.get_ports.empty?
                    to_from.push_middle_from("-m multiport --dports #{rule.get_ports.join(",")}")
                    to_from.push_middle_to("-m multiport --sports #{rule.get_ports.join(",")}")
                  end
                  if rule.icmp? && rule.get_type
                    to_from.push_middle_from(icmp_type(family, rule.get_type))
                  end
                  if rule.connection?
                    to_from.push_middle_from("-m state --state NEW,ESTABLISHED")
                    to_from.push_middle_to("-m state --state RELATED,ESTABLISHED")
                  end
                  write_table(cfg[:table], rule, to_from.factory(cfg[:writer]))
                end
              end
            end
          end
        end

        def self.create_from_iface(ifname, iface, writer)
          iface.firewalls && iface.firewalls.each do |firewall|
            firewall.get_raw && Firewall.write_raw(firewall, firewall.get_raw, ifname, iface, writer.raw)
            firewall.get_nat && Firewall.write_nat(firewall, firewall.get_nat, ifname, iface, writer.nat)
            firewall.get_forward && Firewall.write_forward(firewall, firewall.get_forward, ifname, iface, writer.filter)
            firewall.get_host && Firewall.write_host(firewall, firewall.get_host, ifname, iface, writer.filter)
          end
        end

        def self.create(host, ifname, iface)
          throw 'interface must set' unless ifname
          writer = iface.host.result.etc_network_iptables
          create_from_iface(ifname, iface, writer)
          create_from_iface(ifname, iface.delegate.vrrp.delegate, writer) if iface.delegate.vrrp
          writer_local = host.result.etc_network_interfaces.get(iface)
          writer_local.lines.up("iptables-restore < /etc/network/iptables.cfg")
          writer_local.lines.up("ip6tables-restore < /etc/network/ip6tables.cfg")
        end
      end
    end
  end
end
