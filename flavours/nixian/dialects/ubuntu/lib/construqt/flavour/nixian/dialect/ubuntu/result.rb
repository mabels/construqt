
require 'shellwords'

require_relative 'result/etc_network_vrrp'
require_relative 'result/etc_network_interfaces'
require_relative 'result/etc_network_iptables'
require_relative 'result/etc_conntrackd_conntrackd'
require_relative 'ipsec/ipsec_secret'
require_relative 'ipsec/ipsec_cert_store'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Result
            attr_reader :etc_network_interfaces, :etc_network_iptables, :etc_conntrackd_conntrackd
            attr_reader :ipsec_secret, :ipsec_cert_store, :host
            def initialize(host)
              @host = host
              @etc_network_interfaces = EtcNetworkInterfaces.new(self)
              @etc_network_iptables = EtcNetworkIptables.new
              @etc_conntrackd_conntrackd = EtcConntrackdConntrackd.new(self)
              @etc_network_vrrp = EtcNetworkVrrp.new
              @ipsec_secret = Ipsec::IpsecSecret.new(self)
              @ipsec_cert_store = Ipsec::IpsecCertStore.new(self)
              @result = {}
            end

            def etc_network_vrrp(ifname)
              @etc_network_vrrp.get(ifname)
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
                "Construqt::Flavour::Delegate::DeviceDelegate" => {},
                "Construqt::Flavour::Nixian::Dialect::Ubuntu::Wlan" => { },
                "Construqt::Flavour::Nixian::Dialect::Ubuntu::Bond" => { "ifenslave" => true },
                "Construqt::Flavour::Delegate::VlanDelegate" => { "vlan" => true },
                "Construqt::Flavour::Nixian::Dialect::Ubuntu::Gre" => { },
                "Construqt::Flavour::Delegate::GreDelegate" => {},
                "Construqt::Flavour::Delegate::BridgeDelegate" => { "bridge-utils" => true },
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
                cp::LXC => { "lxc" => true, "ruby" => true, "rubygems-integration" => ['gem install linux-lxc --no-ri --no-rdoc'] },
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

            def setup_ntp(host)
              out = []
              out << "cp /usr/share/zoneinfo/#{host.time_zone || host.region.network.ntp.get_timezone} /etc/localtime"
              # missing /etc/ntp.conf writer
              out
            end

            def sh_is_opt_set
              out = []
              out << "is_opt_set()"
              out << "{"
              out << "opt=$1"
              out << "found=1"
              out << "for i in $ARGS"
              out << "do"
              out << "if [ $i = $opt ]"
              out << "then"
              out << " found=0"
              out << "fi"
              out << "done"
              out << "return $found"
              out << "}"
              out
            end

            def sh_install_packages
              out = []
              out << "install_packages()"
              out << "{"
              out << "packages=$*"
              out << "updates=''"
              out << 'for i in $packages'
              out << 'do'
              out << ' dpkg -l $i 2> /dev/null | grep -q "^ii\s\s*$i\s"'
              out << ' if [ $? != 0 ]'
              out << ' then'
              out << '    updates="$updates $i"'
              out << ' fi'
              out << 'done'
              out << '[ -f /etc/resolv.conf ] && mv /etc/resolv.conf /etc/resolv.conf.temp'
              out << 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf'
              out << 'apt-get -qq -y install $updates'
              out << 'if [ $? != 0 ]'
              out << 'then'
              out << '  apt-get update'
              out << '  apt-get -qq -y install $updates'
              out << 'fi'
              out << '[ -f /etc/resolv.conf.temp ] && mv /etc/resolv.conf.temp /etc/resolv.conf'
              out << '}'
              out
            end

            def commit
              add(EtcNetworkIptables, etc_network_iptables.commitv4, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW4), "etc", "network", "iptables.cfg")
              add(EtcNetworkIptables, etc_network_iptables.commitv6, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW6), "etc", "network", "ip6tables.cfg")
              add(EtcNetworkInterfaces, etc_network_interfaces.commit, Construqt::Resources::Rights.root_0644, "etc", "network", "interfaces")
              @etc_network_vrrp.commit(self)
              ipsec_secret.commit
              ipsec_cert_store.commit

              Lxc.write_deployers(@host)

              out = [<<BASH]
#!/bin/bash
hostname=`hostname`
ARGS=$@
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
BASH
              out += sh_is_opt_set
              out += sh_function_git_add
              out += sh_install_packages

              out << "is_opt_set skip_packages || install_packages #{components_hash.keys.join(" ")}"

              out << <<BASH
if [ ! -d /root/construqt.git ]
then
 echo generate history in /root/construqt.git
 git init --bare /root/construqt.git
fi
BASH


              out += setup_ntp(host)
              out += components_hash.values.select{|i| i.instance_of?(Array) }.flatten

              out += @result.map do |fname, block|
                if host.files
                  next [] if host.files.find{|file| file.path == fname && file.kind_of?(Construqt::Resources::SkipFile) }
                end

                text = block.flatten.select{|i| !(i.nil? || i.strip.empty?) }.join("\n")
                next if text.strip.empty?
                Util.write_str(@host.region, text, @host.name, fname)
                gzip_fname = Util.write_gzip(@host.region, text, @host.name, fname)
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
              out += Lxc.deploy(@host)
              out += [<<BASH]
git --git-dir /root/construqt.git config user.name #{ENV['USER']}
git --git-dir /root/construqt.git config user.email #{ENV['USER']}@construqt.net
git --git-dir /root/construqt.git --work-tree=/ commit -q -m #{Shellwords.escape("#{ENV['USER']} #{`hostname`.strip} #{`git log --pretty=format:"%h - %an, %ar : %s" -1`.strip}")} > /dev/null && echo COMMITED
BASH
              Util.write_str(@host.region, out.join("\n"), @host.name, "deployer.sh")
            end
          end
        end
      end
    end
  end
end
