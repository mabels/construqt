module Construct
module Util
  def self.write_str(str, *path)
    path = File.join("cfgs", *path)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') {|f| f.write(str) }
    Construct.logger.info "Write:#{path}"
    return str
  end
   def self.password(a)
      a
   end
   def self.add_gre_prefix(name)
      unless name.start_with?("gt")
         return "gt"+name
      end
      name
   end
   @clean_if = []
   def self.add_clean_ip_pattern(pat)
     @clean_if << pat
   end
   def self.clean_if(prefix, name)
     unless name.start_with?(prefix)
       name = prefix+name
     end
     name = name.gsub(/[^a-z0-9]/, '')
     @clean_if.each { |pat| name.gsub!(pat, '') }
     name
   end
   def self.clean_bgp(name)
     name.gsub(/[^a-z0-9]/, '_')
   end
end
end
