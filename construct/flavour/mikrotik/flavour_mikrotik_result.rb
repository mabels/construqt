module Construct
module Flavour
module Mikrotik
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
    def prepare(default, cfg, enable = true)
      if enable
        default['disabled'] = Schema.boolean.default(false)
      end
      result = {}
      cfg.each do |key, val|
        unless default[key]
          Construct.logger.warn("cfg unknown key:#{key}") 
        else
          result[key] = val
        end
      end
      keys = {}
      default.each do |key, val| 
        if val.kind_of?(Schema)
          val.field_name = key
          throw "type must set of #{key}" unless val.type?
          throw "required key:#{key} not set" if val.required? and (result[key].nil? or result[key].to_s.empty?)
          result[key] = val.get_default if !val.get_default.nil? && result[key].nil? 
          keys[key] = result[key] if val.key?
        else
          throw "default type has to be a schema #{val}" 
        end
      end
      OpenStruct.new( 
        :key => keys.map{|k,v| "#{k}=#{default[k].serialize(v)}"}.sort.join(" && "), 
        :result => result,
        :add_line => result.select{ |k,v| 
          if default[k].kind_of?(Schema) && default[k].noset?
            false 
          else
              !(v.to_s.empty?) 
          end
        }.map{|k,v| "#{k}=#{default[k].serialize(v)}"}.sort.join(" ")
      )
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
      ret = ["{"] 
      ret << "  :local found [find "+prepared.key+"]"
      ret << "  :if ($found = \"\") do={"
      ret << "    :put "+"/#{path.join(' ')} add #{prepared.add_line}".inspect
      ret << "    add #{prepared.add_line}"
      ret << "  } else={"
      #ret << "    :put "+"/#{path.join(' ')} set #{prepared.add_line}".inspect
      ret << "    :local record [get $found]"
      prepared.result.keys.sort.each do |key|
        next if prepared.result[key].nil?
        val = default[key].serialize(prepared.result[key]) 
        next if val.to_s.empty?
        compare_val = default[key].serialize_compare(prepared.result[key])
        if compare_val
          ret << "    :if (($record->#{key.inspect})!=#{compare_val}) do={"
          ret << "       :put "+"/#{path.join(' ')} set [find #{prepared.key} ] #{key}=#{val}".inspect
          ret << "       set $found #{key}=#{val}"
          ret << "    }"
        else
          ret << "    set $found #{key}=#{val}"
        end
      end
      ret << "  }" 
      ret << "}" 
      add(ret.join("\n"), prepared.key, *path)  
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

        sorted[key] = Util.write_str([ 
            "/#{key}",
            blocks.map{|i|i.block}.join("\n"),
            remove_condition(digests, key),
            ""
          ].join("\n"), File.join(@host.name, "#{path}.rsc"))
      end
      all=["system identity",
      "system script",
      "system scheduler",
      "user",
      "interface",
      "interface bonding",
      "interface bridge",
      "interface bridge port",
      "interface vlan",
      "interface vrrp",
      "interface gre6",
      "ipv6 address",
      "ipv6 route",
      "ip address",
      "ip dns",
      "ip route",
      "ip ipsec proposal",
      "ip ipsec peer",
      "ip ipsec policy",
      "routing filter",
      "routing bgp instance",
      "routing bgp peer"].map do |path|
        if sorted[path] 
          sorted[path]
        else
          Construct.logger.warn "WARNING [#{path}] not found #{sorted.keys.join('-')}" unless sorted[path]
          ""
        end
      end.join("\n")
      Util.write_str(all, File.join(@host.name, "all.rsc"))
    end
  end
end
end
end
