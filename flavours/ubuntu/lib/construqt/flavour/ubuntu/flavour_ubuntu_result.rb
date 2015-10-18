
require 'shellwords'

module Construqt
  module Flavour
    module Ubuntu

      class EtcConntrackdConntrackd
        def initialize(result)
          @result = result
          @others = []
        end

        class Other
          attr_accessor :ifname, :my_ip, :other_ip
        end

        def add(ifname, my_ip, other_ip)
          other = Other.new
          other.ifname = ifname
          other.my_ip = my_ip
          other.other_ip = other_ip
          @others << other
        end

        def commit
          return '' if @others.empty?
          out = [<<CONNTRACKD]
General {
	HashSize 32768
	HashLimit 524288
	Syslog on
	LockFile /var/lock/conntrackd.lock
	UNIX {
		Path /var/run/conntrackd.sock
		Backlog 20
	}
	SocketBufferSize 262142
	SocketBufferSizeMaxGrown 655355
	Filter {
		Protocol Accept {
			TCP
		}
		Address Ignore {
			IPv4_address 127.0.0.1 # loopback
		}
	}
}
Sync {
	Mode FTFW {
   	DisableExternalCache Off
		CommitTimeout 1800
		PurgeTimeout 5
	}
CONNTRACKD
          @others.each do |other|
            out.push(<<OTHER)
  UDP Default {
          IPv4_address #{other.my_ip}
          IPv4_Destination_Address #{other.other_ip}
          Port 3780
          Interface #{other.ifname}
          SndSocketBuffer 24985600
          RcvSocketBuffer 24985600
          Checksum on
  }
OTHER
          end
          out.push("}")
          out.join("\n")
        end
      end

      class EtcNetworkIptables
        def initialize
          @mangle = Section.new('mangle')
          @nat = Section.new('nat')
          @raw = Section.new('raw')
          @filter = Section.new('filter')
        end

        def empty_v4?
          @mangle.empty_v4? && @nat.empty_v4? && @raw.empty_v4? && @filter.empty_v4?
        end

        def empty_v6?
          @mangle.empty_v6? && @nat.empty_v6? && @raw.empty_v6? && @filter.empty_v6?
        end

        class Section
          class Block
            def initialize(section)
              @section = section
              @rows = []
            end

            def empty?
              @rows.empty?
            end

            class Row
              include Util::Chainable
              chainable_attr_value :row, nil
              chainable_attr_value :table, nil
              chainable_attr_value :chain, nil
            end

            class RowFactory
              include Util::Chainable
              chainable_attr_value :table, nil
              chainable_attr_value :chain, nil
              chainable_attr_value :rows, nil
              def create
                ret = Row.new.table(get_table).chain(get_chain)
                get_rows.push(ret)
                ret
              end
            end

            def table(table, chain = nil)
              RowFactory.new.rows(@rows).table(table).chain(chain)
            end

            def prerouting
              table("", 'PREROUTING')
            end

            def postrouting
              table("", 'POSTROUTING')
            end

            def forward
              table("", 'FORWARD')
            end

            def output
              table("", 'OUTPUT')
            end

            def input
              table("", 'INPUT')
            end

            def commit
              #puts @rows.inspect
              tables = @rows.inject({}) do |r, row|
                r[row.get_table] ||= {}
                r[row.get_table][row.get_chain] ||= []
                r[row.get_table][row.get_chain] << row
                r
              end

              return "" if tables.empty?
              ret = ["*#{@section.name}"]
              ret += tables.keys.sort.map do |k|
                v = tables[k]
                if k.empty?
                  v.keys.map{|o| ":#{o} ACCEPT [0:0]" }
                else
                  ":#{k} - [0:0]"
                end
              end

              tables.keys.sort.each do |k,v|
                v = tables[k]
                v.keys.sort.each do |chain|
                  rows = v[chain]
                  table = !k.empty? ? "-A #{k}" : "-A #{chain}"
                  rows.each do |row|
                    ret << "#{table.strip} #{row.get_row.strip}"
                  end
                end
              end

              ret << "COMMIT"
              ret << ""
              ret.join("\n")
            end
          end

          attr_reader :jump_destinations
          def initialize(name)
            @name = name
            @jump_destinations = {}
            @ipv4 = Block.new(self)
            @ipv6 = Block.new(self)
          end

          def empty_v4?
            @ipv4.empty?
          end

          def empty_v6?
            @ipv6.empty?
          end

          def name
            @name
          end

          def ipv4
            @ipv4
          end

          def ipv6
            @ipv6
          end

          def commitv6
            @ipv6.commit
          end

          def commitv4
            @ipv4.commit
          end
        end

        def mangle
          @mangle
        end

        def raw
          @raw
        end

        def nat
          @nat
        end

        def filter
          @filter
        end

        def commitv4
          mangle.commitv4+raw.commitv4+nat.commitv4+filter.commitv4
        end

        def commitv6
          mangle.commitv6+raw.commitv6+nat.commitv6+filter.commitv6
        end
      end

      class EtcNetworkInterfaces
        def initialize(result)
          @result = result
          @entries = {}
        end

        class Entry
          class Header
            MODE_MANUAL = :manual
            MODE_LOOPBACK = :loopback
            MODE_DHCP = :dhcp
            PROTO_INET6 = :inet6
            PROTO_INET4 = :inet
            AUTO = :auto
            def mode(mode)
              @mode = mode
              self
            end

            def dhcpv4
              @mode = MODE_DHCP
              self
            end

            def dhcpv6
              @dhcpv6 = true
              self
            end

            def protocol(protocol)
              @protocol = protocol
              self
            end

            def noauto
              @auto = false
              self
            end

            def initialize(entry)
              @entry = entry
              @auto = true
              @mode = MODE_MANUAL
              @protocol = PROTO_INET4
              @interface_name = nil
            end

            def interface_name(name)
              @interface_name = name
            end

            def get_interface_name
              @interface_name || @entry.iface.name
            end

            def commit
              return "" if @entry.skip_interfaces?
              ipv6_dhcp = "iface #{get_interface_name} inet6 dhcp" if @dhcpv6
              out = <<OUT
# #{@entry.iface.clazz}
#{@auto ? "auto #{get_interface_name}" : ""}
#{ipv6_dhcp||""}
iface #{get_interface_name} #{@protocol.to_s} #{@mode.to_s}
  up   /bin/bash /etc/network/#{get_interface_name}-up.iface
  down /bin/bash /etc/network/#{get_interface_name}-down.iface
OUT
            end
          end

          class Lines
            def initialize(entry)
              @entry = entry
              @lines = []
              @ups = []
              @downs = []
            end

            def up(block, order = 0)
              @ups << [order, block.each_line.map{|i| i.strip }.select{|i| !i.empty? }]
            end

            def down(block, order = 0)
              @downs << [order, block.each_line.map{|i| i.strip }.select{|i| !i.empty? }]
            end

            def add(block)
              @lines += block.each_line.map{|i| i.strip }.select{|i| !i.empty? }
            end

            def write_s(component, direction, blocks)
              @entry.result.add(self.class, <<BLOCK, Construqt::Resources::Rights.root_0755(component), "etc", "network", "#{@entry.header.get_interface_name}-#{direction}.iface")
#!/bin/bash
exec > >(logger -t "#{@entry.header.get_interface_name}-#{direction}") 2>&1
#{blocks.join("\n")}
exit 0
BLOCK
#iptables-restore < /etc/network/iptables.cfg
#ip6tables-restore < /etc/network/ip6tables.cfg
            end

            def ordered_lines(lines)
              result = lines.inject({}){ |r, l| r[l.first] ||=[]; r[l.first] << l.last; r }
              result.keys.sort.map { |key| result[key] }.flatten
            end

            def commit
              write_s(@entry.iface.class.name, "up", ordered_lines(@ups))
              write_s(@entry.iface.class.name, "down", ordered_lines(@downs))
              sections = @lines.inject({}) {|r, line| key = line.split(/\s+/).first; r[key] ||= []; r[key] << line; r }
              sections.keys.sort.map do |key|
                if sections[key]
                  sections[key].map{|j| "  #{j}" }
                else
                  nil
                end
              end.compact.flatten.join("\n")+"\n\n"
            end
          end

          def iface
            @iface
          end

          def initialize(result, iface)
            @result = result
            @iface = iface
            @header = Header.new(self)
            @lines = Lines.new(self)
            @skip_interfaces = false
          end

          def result
            @result
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

          def skip_interfaces?
            @skip_interfaces
          end

          def skip_interfaces
            @skip_interfaces = true
            self
          end

          def commit
            @header.commit + @lines.commit
          end
        end

        def get(iface, name = nil)
          throw "clazz needed #{name || iface.name}" unless iface.clazz
          @entries[name || iface.name] ||= Entry.new(@result, iface)
        end

        def commit
          #      binding.pry
          out = [@entries['lo']]
          clazzes = {}
          @entries.values.each do |entry|
            name = entry.iface.clazz#.name[entry.iface.clazz.name.rindex(':')+1..-1]
            #puts "NAME=>#{name}:#{entry.iface.clazz.name.rindex(':')+1}:#{entry.iface.clazz.name}:#{entry.name}"
            clazzes[name] ||= []
            clazzes[name] << entry
          end

          ['device', 'wlan', 'bond', 'vlan', 'bridge', 'gre'].each do |type|
            out += (clazzes[type]||[]).select{|i| !out.first || i.name != out.first.name }.sort{|a,b| a.name<=>b.name }
          end

          out.flatten.compact.inject("") { |r, entry| r += entry.commit; r }
        end
      end

      class EtcNetworkVrrp
        def initialize
          @interfaces = {}
        end

        class Vrrp
          def initialize
            @masters = []
            @backups = []
          end

          def add_master(master, order = 0)
            @masters << [order, master]
            self
          end

          def add_backup(backup, order = 0)
            @backups << [order, backup]
            self
          end

          def render(lines, direction)
            (["logger '#{direction}'"]+lines).map { |line| "                  #{line}" }.join("\n")
          end

          def ordered_lines(lines)
            result = lines.inject({}){ |r, l| r[l.first] ||=[]; r[l.first] << l.last; r }
            result.keys.sort.map { |key| result[key] }.flatten
          end

          def render_masters
            render(ordered_lines(@masters), 'STARTING:')
          end

          def render_backups
            render(ordered_lines(@backups), 'STOPPING:')
          end
        end

        def get(ifname)
          @interfaces[ifname] ||= Vrrp.new
        end

        def commit(result)
          unless @interfaces.keys.empty?

            result.add(EtcConntrackdConntrackd, result.etc_conntrackd_conntrackd.commit, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::CONNTRACKD), "etc", "conntrackd", "conntrackd.conf")
          end
          @interfaces.keys.sort.each do |ifname|
            vrrp = @interfaces[ifname]
            result.add(self, <<VRRP, Construqt::Resources::Rights.root_0755(Construqt::Resources::Component::VRRP), "etc", "network", "vrrp.#{ifname}.stop.sh")
#!/bin/bash
#{vrrp.render_backups}
exit 0
VRRP
            result.add(self, <<VRRP, Construqt::Resources::Rights.root_0755(Construqt::Resources::Component::VRRP), "etc", "network", "vrrp.#{ifname}.sh")
#!/bin/bash

TYPE=$1
NAME=$2
STATE=$3

case $STATE in
        "MASTER")
#{vrrp.render_masters}
                  exit 0
                  ;;
        "BACKUP")
#{vrrp.render_backups}
                  exit 0
                  ;;
        *)        echo "unknown state"
                  exit 1
                  ;;
esac
VRRP
          end
        end
      end

      class Result
        attr_reader :etc_network_interfaces, :etc_network_iptables, :etc_conntrackd_conntrackd
        def initialize(host)
          @host = host
          @etc_network_interfaces = EtcNetworkInterfaces.new(self)
          @etc_network_iptables = EtcNetworkIptables.new
          @etc_conntrackd_conntrackd = EtcConntrackdConntrackd.new(self)
          @etc_network_vrrp = EtcNetworkVrrp.new
          @result = {}
        end

        def etc_network_vrrp(ifname)
          @etc_network_vrrp.get(ifname)
        end

        def host
          @host
        end

        def add_component(component)
          @result[component] ||= ArrayWithRight.new(Construqt::Resources::Rights.root_0644(component))
        end

        def empty?(name)
          not @result[name]
        end

        class ArrayWithRight < Array
          attr_accessor :right
          def initialize(right)
            self.right = right
          end
          def skip_git?
            !!@skip_git
          end
          def skip_git
            @skip_git = true
          end
        end

        def add(clazz, block, right, *path)
          path = File.join(*path)
          throw "not a right #{path}" unless right.respond_to?('right') && right.respond_to?('owner')
          unless @result[path]
            @result[path] = ArrayWithRight.new(right)
            #binding.pry
            #@result[path] << [clazz.xprefix(@host)].compact
          end
          @result[path] << block+"\n"
          @result[path]
        end

        def replace(clazz, block, right, *path)
          path = File.join(*path)
          replaced = !!@result[path]
          @result.delete(path) if @result[path]
          add(clazz, block, right, *path)
          replaced
        end

        def directory_mode(mode)
          mode = mode.to_i(8)
          0!=(mode & 06) && (mode = (mode | 01))
          0!=(mode & 060) && (mode = (mode | 010))
          0!=(mode & 0600) && (mode = (mode | 0100))
          "0#{mode.to_s(8)}"
        end

        def component_to_packages(component)
          cp = Construqt::Resources::Component
          ret = {
            cp::UNREF => {},
            "Construqt::Flavour::DeviceDelegate" => {},
            "Construqt::Flavour::Ubuntu::Wlan" => { },
            "Construqt::Flavour::Ubuntu::Bond" => { "ifenslave" => true },
            "Construqt::Flavour::VlanDelegate" => { "vlan" => true },
            "Construqt::Flavour::Ubuntu::Gre" => { },
            "Construqt::Flavour::GreDelegate" => {},
            "Construqt::Flavour::BridgeDelegate" => { "bridge-utils" => true },
            cp::NTP => { "ntpd" => true},
            cp::USB_MODESWITCH => { "usb-modeswitch" => true, "usb-modeswitch-data" => true },
            cp::VRRP => { "keepalived" => true },
            cp::FW4 => { "iptables" => true, "ulogd2" => true },
            cp::FW6 => { "iptables" => true, "ulogd2" => true },
            cp::IPSEC => { "strongswan" => true },
            cp::SSH => { "openssh-server" => true },
            cp::BGP => { "bird" => true },
            cp::OPENVPN => { "openvpn" => true },
            cp::DNS => { "bind9" => true },
            cp::RADVD => { "radvd" => true },
            cp::DNSMASQ => { "dnsmasq" => true },
            cp::CONNTRACKD => { "conntrackd" => true, "conntrack" => true },
            cp::LXC => { "lxc" => true, "ruby" => ['gem install linux-lxc --no-ri --no-rdoc'] },
            cp::DHCPRELAY => { "wide-dhcpv6-relay" => true, "dhcp-helper" => true }
          }[component]
          throw "Component with name not found #{component}" unless ret
          ret
        end

        def components_hash
          @result.values.inject({
            "language-pack-en" => true,
            "language-pack-de" => true,
            "git" => true,
            "aptitude" => true,
            "traceroute" => true,
            "tcpdump" => true,
            "strace" => true,
            "lsof" => true,
            "ifstat" => true,
            "mtr-tiny" => true,
            "openssl" => true,
          }) { |r, block| r.merge(component_to_packages(block.right.component)) }
        end



        def lxc_reference_net_config(base_dir)
          ruby = []
          right = Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::LXC)
          ruby << "/etc/lxc/update_network_in_config #{base_dir}/config #{base_dir}/network.config #{base_dir}/update.config.list"
          ruby << "for i in `cat #{base_dir}/update.config.list`"
          ruby << "do"
          ruby << "  git_add /$i #{right.owner} #{right.right} false"
          ruby << "done"
          ruby
        end

        def sh_function_git_add()
          out = []
          out << "import_fname()"
          out << "{"
          out << "  fname=$1"
          out << "  IMPORT_FNAME='/'`dirname $fname`'/.'`basename $fname`'.import'"
          out << "}"
          out << "git_add()"
          out << "{"
          out << "  fname=$1"
          out << "  owner=$2"
          out << "  right=$3"
          out << "  skip_git=$4"
          out << "  import_fname $fname"
          out << "  ifname=$IMPORT_FNAME"
          out << "  chown $owner $ifname"
          out << "  chmod $right $ifname"
          out << "  if [ ! -f /$fname ]"
          out << "  then"
          out << "    mv $ifname /$fname"
          out << "    echo created /$fname to $owner:$right skip_git $skip_git"
          out << "  else"
          out << "    diff -rq $ifname /$fname"
          out << "    if [ $? != 0 ]"
          out << "    then"
          out << "      mv $ifname /$fname"
          out << "      echo updated /$fname to $owner:$right skip_git $skip_git"
          out << "    else"
          out << "      rm $ifname"
          out << "      echo unchanged /$fname to $owner:$right skip_git $skip_git"
          out << "    fi"
          out << '    if [ "$skip_git" = "false" ]'
          out << "    then"
          out << "      git --git-dir /root/construqt.git --work-tree=/ add /$fname"
          out << "    fi"
          out << "  fi"
          out << "}"
          out
        end

        def lxc_deploy(host)
          out = []
          host.region.hosts.get_hosts.select {|h| @host.delegate == h.mother }.each do |lxc|
            next unless lxc.lxc_deploy
            next if lxc.lxc_deploy.empty?
            out << "# LXC Container #{lxc.name} [#{lxc.lxc_deploy}]\n"
            out << '[ "true" = "$(. /etc/default/lxc-net && echo $USE_LXC_BRIDGE)" ] && echo USE_LXC_BRIDGE="false" >> /etc/default/lxc-net'
            base_dir = File.join("/var", "lib", "lxc", lxc.name)
            lxc_rootfs = File.join(base_dir, "rootfs")
            sh_lxc_name =  Shellwords.escape(lxc.name)
            if lxc.lxc_deploy.include? Construqt::Hosts::Lxc::RECREATE
              out << "echo start LXC-RECREATE #{sh_lxc_name}"
              out << "lxc-ls --running | grep -q '#{sh_lxc_name}' && lxc-stop -n '#{sh_lxc_name}'"
              out << "[ -d #{lxc_rootfs}/usr/share] && lxc-destroy -f -n '#{sh_lxc_name}'"
              out << "lxc-create -n '#{sh_lxc_name}' -t #{lxc.flavour.name}"
              out << "chroot #{lxc_rootfs} /bin/bash /root/deployer.sh"
              out << "echo fix config of #{sh_lxc_name} in #{lxc_rootfs}"
              out += lxc_reference_net_config(base_dir)
              out << "lxc-start -d -n '#{sh_lxc_name}'"
            elsif lxc.lxc_deploy.include? Construqt::Hosts::Lxc::RESTART
              out << "echo start LXC-RESTART #{sh_lxc_name}"
              out << "lxc-ls --running | grep -q '#{sh_lxc_name}' && lxc-stop -n '#{sh_lxc_name}'"
              out << "[ -d #{lxc_rootfs}/usr/share ] || lxc-create -n '#{sh_lxc_name}' -t #{lxc.flavour.name}"
              out << "chroot #{lxc_rootfs} /bin/bash /root/deployer.sh"
              out << "echo fix config of #{sh_lxc_name} in #{lxc_rootfs}"
              out += lxc_reference_net_config(base_dir)
              out << "lxc-start -d -n '#{sh_lxc_name}'"
            end
          end
          out
        end


        def commit
          add(EtcNetworkIptables, etc_network_iptables.commitv4, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW4), "etc", "network", "iptables.cfg")
          add(EtcNetworkIptables, etc_network_iptables.commitv6, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW6), "etc", "network", "ip6tables.cfg")
          add(EtcNetworkInterfaces, etc_network_interfaces.commit, Construqt::Resources::Rights.root_0644, "etc", "network", "interfaces")
          @etc_network_vrrp.commit(self)

          host.region.hosts.get_hosts.select {|h| @host.delegate == h.mother }.each do |lxc|
            add(lxc, Util.read_str(lxc.name, "deployer.sh"),
                Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::LXC),
                "/var", "lib", "lxc", lxc.name, "rootfs", "root", "deployer.sh").skip_git
          end

          out = [<<BASH]
#!/bin/bash
hostname=`hostname`
if [ $hostname != "" ]
then
  hostname=`grep '^\s*[^#]' /etc/hostname`
fi
if [ "$hostname" != "#{@host.name}" ]
then
 echo 'You try to run a deploy script on a host which has not the right name $hostname != #{@host.name}'
 exit 47
else
 echo Configure Host #{@host.name}
fi
updates=''
for i in #{components_hash.keys.join(" ")}
do
 dpkg -l $i 2> /dev/null | grep -q "^ii\s\s*$i\s"
 if [ $? != 0 ]
 then
    updates="$updates $i"
 fi
done
if [ ! -f /etc/resolv.conf ]
then
  # during boot strap there could be no resolv.conf
  echo "nameserver 8.8.8.8" > /etc/resolv.conf
fi
apt-get -qq -y install $updates
if [ ! -d /root/construqt.git ]
then
 echo generate history in /root/construqt.git
 git init --bare /root/construqt.git
fi
BASH
          out += components_hash.values.select{|i| i.instance_of?(Array) }.flatten

          out += sh_function_git_add
          out += @result.map do |fname, block|
            if host.files
              next [] if host.files.find{|file| file.path == fname && file.kind_of?(Construqt::Resources::SkipFile) }
            end
            text = block.flatten.select{|i| !(i.nil? || i.strip.empty?) }.join("\n")
            next if text.strip.empty?
            Util.write_str(text, @host.name, fname)
            gzip_fname = Util.write_gzip(text, @host.name, fname)
            #          binding.pry
            #
            [
              File.dirname("/#{fname}").split('/')[1..-1].inject(['']) do |res, part|
                res << File.join(res.last, part); res
              end.select{|i| !i.empty? }.map do |i|
                "[ ! -d #{i} ] && mkdir #{i} && chown #{block.right.owner} #{i} && chmod #{directory_mode(block.right.right)} #{i}"
              end,
              "import_fname #{fname}",
              "openssl enc -base64 -d <<BASE64 | gunzip > $IMPORT_FNAME", Base64.encode64(IO.read(gzip_fname)).chomp, "BASE64",
              "git_add #{["/"+fname, block.right.owner, block.right.right, block.skip_git?].map{|i| '"'+Shellwords.escape(i)+'"'}.join(' ')}"
            ]
          end.flatten
          out += lxc_deploy(@host)
          out += [<<BASH]
git --git-dir /root/construqt.git config user.name #{ENV['USER']}
git --git-dir /root/construqt.git config user.email #{ENV['USER']}@construqt.net
git --git-dir /root/construqt.git --work-tree=/ commit -q -m #{Shellwords.escape("#{ENV['USER']} #{`hostname`.strip} #{`git log --pretty=format:"%h - %an, %ar : %s" -1`.strip}")} > /dev/null && echo COMMITED
BASH
          Util.write_str(out.join("\n"), @host.name, "deployer.sh")
        end
      end
    end
  end
end
