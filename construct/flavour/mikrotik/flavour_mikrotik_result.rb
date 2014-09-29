module Construct
module Flavour
module Mikrotik
	class Result
		def initialize(host)
      @remove_pre_condition = {}
			@host = host
			@result = {}
		end
    def self.once(host)
    end
		def empty?(name)
			not @result[name]
		end
    def prepare(default, cfg, enable = true)
      result = {}
      cfg.each do |key, val|
        throw "cfg unknown key:#{key}" unless default[key]
        result[key] = default[key].type.serialize(val)
      end
      keys = {}
      default.each do |key, val| 
        if val.kind_of?(Schema)
          throw "type must set of #{key}" unless val.type
          throw "required key:#{key} not set" if val.required? and (result[key].nil? or result[key].to_s.empty?)
          result[key] = val.type.serialize(val.get_default) if val.get_default && !result[key]
          keys[key] = result[key] if val.key?
        else
          throw "default type has to be a schema #{val}" 
        end
      end
      result['disabled'] = 'no' if enable
      OpenStruct.new( 
        :key => keys.map{|k,v| "#{k}=#{v}"}.sort.join(" && "), 
        :result => result,
        :add_line => result.select{ |k,v| 
          if default[k].kind_of?(Schema) && default[k].noset?
            false 
          else
              !(v.to_s.empty?) 
          end
        }.map{|k,v| "#{k}=#{v}"}.sort.join(" ")
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
      prepared = prepare(default, cfg)
      ret = ["{"] 
      ret << "  :local found [find "+prepared.key+"]"
      ret << "  :if ($found = \"\") do={"
      ret << "    :put "+"/#{path.join(' ')} add #{prepared.add_line}".inspect
      ret << "    add #{prepared.add_line}"
      ret << "  } else={"
      ret << "    :put "+"/#{path.join(' ')} set #{prepared.add_line}".inspect
      ret << "    :set found [get $found]"
      prepared.result.keys.sort.each do |key|
        val = prepared.result[key]
        next if val.to_s.empty?
        ret << "    :if (($found->#{key.inspect})!=#{val}) do={ set $found #{key}=#{val} }"
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
      @host.flavour.pre_clazzes { |clazz| clazz.once(@host) }
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
          puts "WARNING [#{path}] not found #{sorted.keys.join('-')}" unless sorted[path]
          ""
        end
      end.join("\n")
      Util.write_str(all, File.join(@host.name, "all.rsc"))
		end
	end
end
end
end
