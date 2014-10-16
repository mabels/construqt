
module Construct
module Flavour
module Ubuntu

  def self.root
    OpenStruct.new :right => "0644", :owner => 'root'
  end

  def self.root_600
    OpenStruct.new :right => "0600", :owner => 'root'
  end

  def self.root_644
    OpenStruct.new :right => "0644", :owner => 'root'
  end

  def self.root_755
    OpenStruct.new :right => "0600", :owner => 'root'
  end

  class EtcNetworkInterfaces
    def initialize()
      @entries = {}
    end
    def self.prefix(unused)
    end
    class Entry
      class Header
        MODE_MANUAL = :manual
        MODE_DHCP = :dhcp
        MODE_LOOPBACK = :loopback
        PROTO_INET6 = :inet6
        PROTO_INET4 = :inet
        AUTO = :auto
        def mode(mode)
          @mode = mode
          self
        end
        def protocol(protocol)
          @protocol = protocol
          self
        end
        def noauto
          @auto = false
        end
        def initialize(entry)
          @entry = entry
          @auto = true
          @mode = MODE_MANUAL
          @protocol = PROTO_INET4
        end
        def commit
          out = "\n\n"
          out += "# #{@entry.iface.clazz.name}\n"
          out += "auto #{@entry.name}\n" if @auto
          out += "iface #{@entry.name} #{@protocol.to_s} #{@mode.to_s}\n" 
          out
        end
      end
      class Lines
        def initialize(entry)
          @entry = entry
          @lines = []
        end
        def add(block)
          @lines += block.each_line.map{|i| i.strip }.select{|i| !i.empty? }
        end
        def commit
          @lines.map{|i| i.each_line.map{|j| "  #{j}" } }.flatten.join("\n")
        end
      end
      def iface
        @iface
      end
      def initialize(iface)
        @iface = iface
        @header = Header.new(self)
        @lines = Lines.new(self)
      end
      def name
        @iface.name
      end
      def header
        @header
      end
      def lines
        @lines
      end
      def commit
        @header.commit + @lines.commit
      end
    end
    def get(iface) 
      throw "clazz needed #{iface.name}" unless iface.clazz
      @entries[iface.name] ||= Entry.new(iface)
    end
    def commit
      #binding.pry
      out = [@entries['lo']]
      clazzes = {}
      @entries.values.each do |entry|
        name = entry.iface.clazz.name[entry.iface.clazz.name.rindex(':')+1..-1]
        puts "NAME=>#{name}:#{entry.iface.clazz.name.rindex(':')+1}:#{entry.iface.clazz.name}:#{entry.name}"
        clazzes[name] ||= []
        clazzes[name] << entry
      end
      ['Device', 'Bond', 'Vlan', 'Bridge', 'Gre'].each do |type|
        out += (clazzes[type]||[]).select{|i| !out.first || i.name != out.first.name }.sort{|a,b| a.name<=>b.name }
      end
      out.flatten.compact.inject("") { |r, entry| r += entry.commit; r }
    end
  end

  class Result
    def initialize(host)
      @host = host
      @etc_network_interfaces = EtcNetworkInterfaces.new
      @result = {}
    end
    def etc_network_interfaces
      @etc_network_interfaces
    end
    def host
      @host
    end
    def empty?(name)
      not @result[name]
    end
    class ArrayWithRight < Array
      attr_accessor :right
      def initialize(right)
        self.right = right
      end
    end
    def add(clazz, block, right, *path)
      path = File.join(*path)
      throw "not a right #{path}" unless right.respond_to?('right') && right.respond_to?('owner')
      unless @result[path]
        @result[path] = ArrayWithRight.new(right)
        @result[path] << [clazz.prefix(path)]
      end
      @result[path] << block+"\n"
    end
    def directory_mode(mode)
      mode = mode.to_i(8)
      0!=(mode & 06) && (mode = (mode | 01))
      0!=(mode & 060) && (mode = (mode | 010)) 
      0!=(mode & 0600) && (mode = (mode | 0100))
      "0#{mode.to_s(8)}"
    end
    def commit
      add(EtcNetworkInterfaces, etc_network_interfaces.commit, Ubuntu.root_644, "etc", "network", "interfaces")
    out = [<<BASH]
#!/bin/bash, 
hostname=`hostname`
if [ \$hostname\ != #{@host.name} ]
'then'
 echo 'You try to run a deploy script on a host which has not the right name $hostname != #{@host.name}'
else
 echo Configure Host #{@host.name}
'fi'
updates=''
for i in language-pack-en language-pack-de git aptitude traceroute vlan bridge-utils tcpdump mtr-tiny bird keepalived \\
strace iptables conntrack openssl racoon
do
 dpkg -l $i > /dev/null 2> /dev/null, 
 if [ $? != 0 ]
 then
    updates=\$updates $i\
 fi
done
apt-get -qq -y install $updates
if [ ! -d /root/construct.git ]
then
 echo generate history in /root/construct.git
 git init --bare /root/construct.git
fi
BASH
    out += @result.map do |fname, block|
      text = block.compact.join("\n")
      next if text.strip.empty?
      Util.write_str(text, @host.name, fname)
#          binding.pry
      #
      [
        File.dirname("/#{fname}").split('/')[1..-1].inject(['']) do |res, part| 
          res << File.join(res.last, part); res 
        end.select{|i| !i.empty? }.map do |i| 
          "[ ! -d #{i} ] && mkdir #{i} && chown #{block.right.owner} #{i} && chmod #{directory_mode(block.right.right)} #{i}"
        end,
        "openssl enc -base64 -d > /#{fname}.import <<BASE64", Base64.encode64(text), "BASE64",
        <<BASH]
chown #{block.right.owner} /#{fname}.import
chmod #{block.right.right} /#{fname}.import
if [ ! -f /#{fname} ]
then
    mv /#{fname}.import /#{fname}
    echo created #{fname} to #{block.right.owner}:#{block.right.right}
else
  diff -rq /#{fname}.import /#{fname}
  if [ $? != 0 ]
  then
    mv /#{fname}.import /#{fname}
    echo updated #{fname} to #{block.right.owner}:#{block.right.right}
  fi
  git --git-dir /root/construct.git --work-tree=/ add /#{fname}
fi
BASH
    end.flatten
    out += [<<BASH] 
git --git-dir /root/construct.git config user.name #{ENV['USER']}
git --git-dir /root/construct.git config user.email #{ENV['USER']}@construct.net
git --git-dir /root/construct.git --work-tree=/ commit -q -m '#{ENV['USER']} #{`hostname`.strip} #{`git log --pretty=format:"%h - %an, %ar : %s" -1`.strip}' > /dev/null && echo COMMITED
BASH
    Util.write_str(out.join("\n"), @host.name, "deployer.sh")
  end
  end

end
end
end
