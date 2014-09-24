module Construct
module Flavour
module Mikrotik
	class Result
		def initialize(host)
			@host = host
			@result = {}
		end
    def self.once(host)
    end
		def empty?(name)
			not @result[name]
		end
    def render_mikrotik_set_direct(default, cfg, *path)
      result = {}
      cfg.each do |key, val|
        result[key] = val
      end
      required = {}
      default.each do |key, val| 
        required[key] = result[key] unless val
        result[key] ||= val 
        throw "required key:#{key} not set" unless result[key]
      end
      assigned = result.map{|k,v| "#{k}=#{v.to_s}"}.sort
      add("set #{assigned.join(' ')}", nil, *path)
    end
    def render_mikrotik_set_by_key(default, cfg, *path)
      result = {}
      keys = []
      default.each do |key,val|
        if val.nil?
          keys << "#{key}=#{cfg[key].to_s}"
          throw "required key:#{key} not set" unless cfg[key]
        else
          result[key] = cfg[key] || default[key]
        end
      end

      assigned = result.map{|k,v| "#{k}=#{v.to_s}"}.sort
      add("set [ find #{keys.join(" && ")} ] #{assigned.join(' ')}", nil, *path)
    end
    def render_mikrotik(default, cfg, *path) 
      black_list = {
        "interface bonding" => { "mode" => true }
      }[path.join(" ")]
      result = {}
      cfg.each do |key, val|
        result[key] = val
      end
      required = {}
      default.each do |key, val| 
        required[key] = result[key] unless val
        result[key] ||= val 
        throw "required key:#{key} not set" unless result[key]
      end
      plain_assigned = result.select{|k,v| !(v.to_s.empty? || black_list && black_list[k]) }.map{|k,v| "#{k}=#{v.to_s}"}.sort
      add_line = plain_assigned.join(" ")
      digest = Digest::MD5.hexdigest(add_line)
      result['comment'] = digest
      result['disabled'] = 'no'
      assigned = result.select{|k,v| !(v.to_s.empty?) }.map{|k,v| "#{k}=#{v.to_s}"}.sort
      add_line = assigned.join(" ")

      ret = ["{"] 
      ret << "  :local found [find "+plain_assigned.join(" && ")+"]"
      ret << "  :if ($found = \"\") do={"
      ret << "    :put "+"/#{path.join(' ')} add #{assigned.join(" ")}".inspect
      ret << "    add #{add_line}"
      ret << "  } else={"
      ret << "    :put "+"/#{path.join(' ')} set #{assigned.join(" ")}".inspect
      ret << "    :set found [get $found]"
      result.keys.sort.each do |key|
        val = result[key]
        ret << "    :if (($found->#{key.inspect})!=#{val.inspect}) do={ set $found #{key}=#{val.inspect} }"
      end
      ret << "  }" 
      ret << "}" 
      ret = ret.join("\n")
      add(ret, digest, *path)  
    end
		def add(block, digest, *path)
			key = File.join(*path)
      @result[key] ||= []
			@result[key] << OpenStruct.new(:digest => digest, :block => block, :path => path)
      @result[key]
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
            digests.empty? ? "" : ("remove [find "+digests.map{|i| "comment!=#{i.digest}"}.join(" && ")+"]"),
            ""
          ].join("\n"), File.join(@host.name, "#{path}.rsc"))
      end
      all=["system identity",
      "user",
      "interface",
      "interface bonding",
      "interface vlan",
      "interface bridge",
      "interface vrrp",
      "interface gre6",
      "ipv6 address",
      "ip address",
      "ip route",
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
