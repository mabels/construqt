module Construqt
  module Flavour
    class Mikrotik
      class Result
        def initialize(host)
          @remove_pre_condition = {}
          @host = host
          @result = {}
        end

        def host
          @host
        end

        def empty?(name)
          not @result[name]
        end

        def break_into_lines(line, break_len = 7000, line_ext = " \\")
          return [line] if line.length <= break_len
          last_break = last_space = last_equal = 0
          lines = []
          chars = line.split("")
          line_len = pos = 0
          while pos < chars.length
            if pos > 0 && line_len >= break_len
              if last_space > 0 && last_equal == 0
                  lines << chars[last_break..last_space].join("") + line_ext
                  pos = last_space
              else
                  lines << chars[last_break..pos].join("") + line_ext
              end
              line_len = 0
              last_break = pos + 1
              last_space = last_equal = 0
            else
              c = chars[pos]
              if [' ',"\t"].include?(c)
                last_space = pos
                last_equal = 0
              elsif c == '=' && chars[pos+1] == '"' && last_equal == 0
                last_equal = pos
              end
            end
            line_len += 1
            pos += 1
          end
          lines << chars[last_break..-1].join("")
          lines
        end

        def write_str_crnl(region, str, *path)
          r = []
          s = str.lines.map(&:chomp).each do |line|
            r << break_into_lines(line)
          end
          Util.write_str(region, r.join("\r\n"), *path)
        end

        def prepare(default, cfg, enable = true)
          if enable
            default['disabled'] = Schema.boolean.default(false)
          end

          result = {}
          cfg.each do |key, val|
            unless default[key]
              Construqt.logger.debug("skip cfg unknown key:#{key} val:#{val}")
            else
              result[key] = val
            end
          end

          keys = {}
          default.each do |key, val|
            if val.kind_of?(Schema)
              val.field_name = key
              throw "type must set of #{key}" unless val.type?
              throw "required key:#{key.class.name} not set #{@host.name}:#{key}" if val.required? && !val.isSet?(result[key])
              result[key] = val.get_default if !val.get_default.nil? && result[key].nil?
              keys[key] = result[key] if val.key?
            else
              throw "default type has to be a schema #{val}"
            end
          end

          OpenStruct.new(
            :key => keys.keys.sort{|a,b| default[a].key_order <=> default[b].key_order }
                        .select{|k| keys[k] }
                        .map{|k| v=keys[k]; render_term(default, k, v) }.join(" && "),
            :result => result,
            :add_line => result.select{ |k,v|
              if default[k].kind_of?(Schema) && default[k].noset?
                false
              else
                !v.nil?
              end
            }.map{|k,v| render_term(default, k, v) }.sort.join(" ")
          )
        end

        def render_term(default, k, v)
          if (v == Schema::DISABLE)
            "!#{k}"
          else
            "#{k}=#{default[k].serialize(v)}"
          end
        end

        def render_mikrotik_set_direct(default, cfg, *path)
          prepared = prepare(default, cfg, false)
          add("set #{prepared.add_line}", nil, *path)
        end

        def render_mikrotik_set_by_key(default, cfg, *path)
          prepared = prepare(default, cfg)
          add("set [ find #{prepared.key} ] #{prepared.add_line}", nil, *path)
        end

        def render_mikrotik(default, cfg, *path)
          enable = !cfg['no_auto_disable'] # HACK
          cfg.delete("no_auto_disable")
          prepared = prepare(default, cfg, enable)
          add(Construqt::Util.render(binding, "result_render.erb"), prepared.key, *path)
        end

        def add(block, digest, *path)
          key = File.join(*path)
          @result[key] ||= []
          @result[key] << OpenStruct.new(:digest => digest, :block => block, :path => path)
          @result[key]
        end

        def add_remove_pre_condition(condition, *path)
          @remove_pre_condition[path.join(' ')] = condition
        end

        def remove_condition(digests, key)
          #binding.pry if key == "interface wireless security-profiles"
          condition = @remove_pre_condition[key]
          if condition
            condition = "(#{condition})"
          end

          if digests.nil? || digests.compact.empty?
            digest = nil
          else
            digest = "(!(#{digests.map{|i| "(#{i.digest})"}.join(" || ")}))"
          end

          term = [condition, digest].compact.join(" && ")
          term.empty? ? "" : "remove [ find #{term} ]"
        end

        def commit
          sorted = {}
          @result.map do |path, blocks|
            key = blocks.first.path.join(' ')
            digests = blocks.select{|i| i.digest }

            sorted[key] = write_str_crnl(@host.region, [
              "/#{key}",
              blocks.map{|i|i.block}.join("\n"),
              remove_condition(digests, key),
              ""
            ].join("\n"), File.join(@host.name, "#{path}.rsc"))
          end

          all=[
            "system identity",
            "system clock",
            "system ntp client",
            "system script",
            "system scheduler",
            "user",
            "interface",
            "interface bonding",
            "interface wireless security-profiles",
            "interface wireless",
            "interface vlan",
            "interface bridge",
            "interface bridge port",
            "interface vrrp",
            "interface gre6",
            "ipv6 address",
            "ipv6 firewall mangle",
            "ipv6 route",
            "ip address",
            "ip dns",
            "ip firewall mangle",
            "ip route",
            "ip ipsec proposal",
            "ip ipsec peer",
            "ip ipsec policy",
            "routing filter",
            "routing bgp instance",
            "routing bgp peer",
            "tool graphing interface",
            "ip service",
            "snmp"
          ].map do |path|
              if sorted[path]
                sorted[path]
              else
                Construqt.logger.warn "WARNING [#{path}] not found #{sorted.keys.join('-')}" unless sorted[path]
                ""
              end
            end.join("\r\n")
            Util.write_str(@host.region, all, File.join(@host.name, "all.rsc"))
        end
      end
    end
  end
end
