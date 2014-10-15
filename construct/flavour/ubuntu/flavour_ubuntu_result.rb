
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
  
  class Result
    def initialize(host)
      @host = host
      @result = {}
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
    out = ["#!/bin/bash", 
           "for i in git aptitude traceroute vlan bridge-utils tcpdump mtr-tiny bird keepalived strace iptables conntrack openssl racoon",
           "do",
           "  dpkg -l $i > /dev/null", 
           "  [ $? != 0 ] && apt-get -q -y install $i",
           "done",
           "if [ ! -d /root/construct.git ]",
           "then",
           "  echo generate history in /root/construct.git",
           "  git init --bare /root/construct.git",
           "fi",
          ]
    out += @result.map do |fname, block|
      text = block.join("\n")
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
        "openssl enc -base64 -d > /#{fname}.import <<BASE64",
        Base64.encode64(text),
        "BASE64",
        "chown #{block.right.owner} /#{fname}.import",
        "chmod #{block.right.right} /#{fname}.import",
        "if [ ! -f /#{fname} ]",
        "then",
          "  mv /#{fname}.import /#{fname}",
          "  echo created #{fname} to #{block.right.owner}:#{block.right.right}",
        "else",
          "diff -rq /#{fname}.import /#{fname}",
          "if [ $? != 0 ]",
          "then",
          "  mv /#{fname}.import /#{fname}",
          "  echo updated #{fname} to #{block.right.owner}:#{block.right.right}",
          "fi",
          "git --git-dir /root/construct.git --work-tree=/ add /#{fname}",
        "fi"
      ]
    end.flatten
    out += [ 
      "git --git-dir /root/construct.git config user.name #{ENV['USER']}",
      "git --git-dir /root/construct.git config user.email #{ENV['USER']}@construct.net",
      "git --git-dir /root/construct.git --work-tree=/ commit -q -m '#{ENV['USER']} #{`hostname`.strip} #{`git log --pretty=format:"%h - %an, %ar : %s" -1`.strip}' > /dev/null && echo COMMITED" ]
    Util.write_str(out.join("\n"), @host.name, "deployer.sh")
  end
  end

end
end
end
