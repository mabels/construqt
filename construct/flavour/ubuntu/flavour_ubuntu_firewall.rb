module Construct
module Flavour
module Ubuntu
  
  module Firewall
      class ToFrom
        extend Util::Chainable
        chainable_attr_value :middle, nil
        chainable_attr_value :middle_to, nil
        chainable_attr_value :middle_from, nil
        chainable_attr_value :end, nil
        chainable_attr_value :end_to, nil
        chainable_attr_value :end_from, nil
        chainable_attr_value :factory, nil
        chainable_attr_value :ifname, nil
        chainable_attr :only_output, true

        def space_before(str)
          if str.nil? or str.empty?
            ""
          else
            " "+str.strip
          end
        end
        def get_end_to
          return space_before(@end_to) if @end_to
          return space_before(@end)
        end
        def get_end_from
          return space_before(@end_from) if @end_from
          return space_before(@end) 
        end
        def get_middle_to
          return space_before(@middle_to) if @middle_to
          return space_before(@middle) 
        end
        def get_middle_from
          return space_before(@middle_from) if @middle_from
          return space_before(@middle) 
        end
        def output_ifname
          return space_before("-o #{@ifname}") if @ifname 
          return ""
        end
        def input_ifname
          return space_before("-i #{@ifname}") if @ifname 
          return ""
        end
        def has_to? 
          @middle || @middle_to || @end || @end_to 
        end
        def has_from? 
          @middle || @middle_from || @end || @end_from 
        end
        def factory!
          get_factory.create
        end
      end

      def self.write_table(iptables, rule, to_from)
        family = iptables=="ip6tables" ? Construct::Addresses::IPV6 : Construct::Addresses::IPV4
        from_list = Construct::Tags.ips(rule.get_from, family)
        to_list = Construct::Tags.ips(rule.get_to, family)
        #puts ">>>>>#{from_list.inspect}"
        #puts ">>>>>#{state.inspect} end_to:#{state.end_to}:#{state.end_from}:#{state.middle_to}#{state.middle_from}"
        action_i = action_o = rule.get_action
        if to_list.empty? && from_list.empty?
          to_from.factory!.row("#{to_from.output_ifname}#{to_from.get_middle_to} -j #{rule.get_action}#{to_from.get_end_to}")
          unless to_from.only_output?
            to_from.factory!.row("#{to_from.input_ifname}#{to_from.get_middle_from} -j #{rule.get_action}#{to_from.get_end_to}")
          end
        end
        if to_list.length > 1
          action_o = "I.#{rule.object_id.to_s(32)}"
          action_i = "O.#{rule.object_id.to_s(32)}"
          to_list.each do |ip|
            to_from.factory!.table(action_o).row("#{to_from.output_ifname} -d #{ip.to_string} -j #{rule.get_action}")
            unless to_from.only_output?
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
          to_from.factory!.row("#{to_from.output_ifname} -s #{ip.to_string}#{from_dst}#{to_from.get_middle_from} -j #{action_o}#{to_from.get_end_to}")
          unless to_from.only_output?
            to_from.factory!.row("#{to_from.input_ifname}#{to_src} -d #{ip.to_string}#{to_from.get_middle_to} -j #{action_i}#{to_from.get_end_to}")
          end
        end
      end

      def self.write_raw(raw, ifname, iface, writer)
        raw.rules.each do |rule|
          throw "ACTION must set #{ifname}" unless rule.get_action
          if rule.prerouting? 
            to_from = ToFrom.new.ifname(ifname)
            write_table("iptables", rule, to_from.factory(writer.ipv4.prerouting))
            write_table("ip6tables", rule, to_from.factory(writer.ipv4.prerouting))
          end
          if rule.output?
            to_from = ToFrom.new.ifname(ifname)
            write_table("iptables", rule, to_from.factory(writer.ipv4.output))
            write_table("ip6tables", rule, to_from.factory(writer.ipv6.output))
          end
        end
      end

      def self.write_nat(nat, ifname, iface, writer)
        nat.rules.each do |rule|
          throw "ACTION must set #{ifname}" unless rule.get_action
          throw "TO_SOURCE must set #{ifname}" unless rule.to_source?
          if rule.to_source? && rule.postrouting?
            src = iface.address.ips.select{|ip| ip.ipv4?}.first 
            throw "missing ipv4 address and postrouting and to_source is used #{ifname}" unless src
            to_from = ToFrom.new.only_output.end_to("--to-source #{src}").ifname(ifname).factory(writer.ipv4.postrouting)
            write_table("iptables", rule, to_from)
          end
        end
      end


      def self.write_forward(forward, ifname, iface, writer)
        forward.rules.each do |rule|
          throw "ACTION must set #{ifname}" unless rule.get_action
          if rule.get_log
            to_from = ToFrom.new.ifname(ifname)
              .end_to("--nflog-prefix o:#{rule.get_log}:#{ifname}")
              .end_from("--nflog-prefix i:#{rule.get_log}:#{ifname}")
            write_table("iptables", rule.clone.action("NFLOG"), to_from.factory(writer.ipv4.forward))
            write_table("ip6tables", rule.clone.action("NFLOG"), to_from.factory(writer.ipv6.forward))
          end
          to_from = ToFrom.new.ifname(ifname)
          if rule.connection?
            to_from.middle_from("-m state --state NEW,ESTABLISHED")
            to_from.middle_to("-m state --state RELATED,ESTABLISHED")
          end
          write_table("iptables", rule, to_from.factory(writer.ipv4.forward))
          write_table("ip6tables", rule, to_from.factory(writer.ipv6.forward))
        end
      end

      def self.create(host, ifname, iface)   
        throw 'interface must set' unless ifname
        writer = iface.host.result.delegate.etc_network_iptables
        iface.firewalls && iface.firewalls.each do |firewall|
          firewall.get_raw && Firewall.write_raw(firewall.get_raw, ifname, iface, writer.raw) 
          firewall.get_nat && Firewall.write_nat(firewall.get_nat, ifname, iface, writer.nat) 
          firewall.get_forward && Firewall.write_forward(firewall.get_forward, ifname, iface, writer.filter) 
        end
      end
  end
end
end
end
