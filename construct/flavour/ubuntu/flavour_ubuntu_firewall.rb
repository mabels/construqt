module Construct
module Flavour
module Ubuntu
  
  module Firewall
      class State
        extend Util::Chainable
        chainable_attr_value :to, nil
        chainable_attr_value :from, nil

        def initialize
          @middle = true
          @end = false
        end
        
        def middle?
          @middle
        end
        def middle
          @end = false
          @middle = true
          self
        end
        def end?
          @end
        end
        def end
          @end = true
          @middle = false
          self
        end

        def space_before(str)
          if str.nil? or str.empty?
            ""
          else
            " "+str.strip
          end
        end
        def in_out_equal?
          get_from == get_to
        end
        def end_to
          return "" unless end?
          space_before(get_to)
        end
        def end_from
          return "" unless end?
          space_before(get_from) 
        end
        def middle_to
          return "" unless middle?
          space_before(get_to) 
        end
        def middle_from
          return "" unless middle?
          space_before(get_from)
        end

      end
      def self.write_table(iptables, ifdirection, ifname, rule, state, writer_factory)
        puts state.inspect
        family = iptables=="ip6tables" ? Construct::Addresses::IPV6 : Construct::Addresses::IPV4
        from_list = Construct::Tags.ips(rule.get_from, family)
        to_list = Construct::Tags.ips(rule.get_to, family)
        #puts ">>>>>#{from_list.inspect}"
        puts ">>>>>#{state.inspect} end_to:#{state.end_to}:#{state.end_from}:#{state.middle_to}#{state.middle_from}"
        action_i = action_o = rule.get_action
        if to_list.empty? && from_list.empty?
            if state.in_out_equal?
              writer_factory.call.row("#{ifdirection} #{ifname}#{state.middle_to} -j #{rule.get_action}#{state.end_to}")
            else 
              if state.has_to?
                writer_factory.call.row("#{ifdirection} #{ifname}#{state.middle_to} -j #{rule.get_action}#{state.end_to}")
              elsif state.has_from?
                writer_factory.call.row("#{ifdirection} #{ifname}#{state.middle_from} -j #{rule.get_action}#{state.end_to}")
              end
            end
        end
        if to_list.length > 1
          action_o = "I.#{rule.object_id.to_s(32)}"
          action_i = "O.#{rule.object_id.to_s(32)}"
          to_list.each do |ip|
            writer_factory.call.table(action_o).row("#{ifdirection} #{ifname} -d #{ip.to_string} -j #{rule.get_action}")
            writer_factory.call.table(action_i).row("#{ifdirection} #{ifname} -s #{ip.to_string} -j #{rule.get_action}")
          end
        elsif to_list.length == 1
          from_dst = " -d #{to_list.first.to_string}" 
          to_src = " -s #{to_list.first.to_string}"
        else 
          from_dst = to_src =""
        end
        from_list.each do |ip|
          writer_factory.call.row("#{ifdirection} #{ifname} -s #{ip.to_string}#{from_dst}#{state.middle_from} -j #{action_o}#{state.end_to}")
          if !state.in_out_equal?
            writer_factory.call.row("#{ifdirection} #{ifname}#{to_src} -d #{ip.to_string}#{state.middle_to} -j #{action_i}#{state.end_to}")
          end
        end
      end

      def self.write_raw(raw, ifname, iface, writer)
        raw.rules.each do |rule|
          throw "ACTION must set #{ifname}" unless rule.get_action
          if rule.prerouting? 
            write_table("iptables", "-i", ifname, rule, State.new.to("").from(""),  lambda{writer.ipv4.prerouting}) 
            write_table("ip6tables", "-i", ifname, rule, State.new.to("").from(""),  lambda{writer.ipv6.prerouting}) 
          end
          if rule.output?
            write_table("iptables", "-o", ifname, rule, State.new.to("").from(""),  lambda{writer.ipv4.output}) 
            write_table("ip6tables", "-o", ifname, rule, State.new.to("").from(""),  lambda{writer.ipv6.output}) 
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
            state = State.new.end.to("--to-source #{src}").from("--to-source #{src}")
            write_table("iptables", "-o", ifname, rule, state, lambda{writer.ipv4.postrouting})

#            writer.ipv4.postrouting.row("-o #{ifname} --to-source #{src} -j #{rule.get_action}")
          end
        end
      end


      def self.write_forward(forward, ifname, iface, writer)
        forward.rules.each do |rule|
          throw "ACTION must set #{ifname}" unless rule.get_action
          if rule.get_log
            ext = "--nflog-prefix #{"#{rule.get_log}:#{ifname}".inspect}"
            state = State.new.middle.end.to(ext).from(ext)
            write_table("iptables", "-o", ifname, rule.clone.action("NFLOG"), state, lambda{writer.ipv4.forward})
            write_table("ip6tables", "-o", ifname, rule.clone.action("NFLOG"), state, lambda{writer.ipv6.forward})
          end
          state = State.new.middle.to("").from("")
          if rule.connection?
            state.from("-m state --state NEW,ESTABLISHED")
            state.to("-m state --state RELATED,ESTABLISHED")
          end
          write_table("iptables", "-o", ifname, rule, state, lambda{writer.ipv4.forward})
          write_table("ip6tables", "-o", ifname, rule, state, lambda{writer.ipv6.forward})
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
