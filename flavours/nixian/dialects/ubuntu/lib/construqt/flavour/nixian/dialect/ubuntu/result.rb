
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
              @result[component] ||= ArrayWithRightAndClazz.new(Construqt::Resources::Rights.root_0644(component), component.to_sym)
            end

            def empty?(name)
              not @result[name]
            end

            class ArrayWithRightAndClazz < Array
              attr_accessor :right, :clazz
              def initialize(right, clazz)
                self.right = right
                self.clazz = clazz
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
                @result[path] = ArrayWithRightAndClazz.new(right, clazz)
                #binding.pry
                #@result[path] << [clazz.xprefix(@host)].compact
              end
              throw "clazz missmatch for path:#{path} [#{@result[path].clazz.class.name}] [#{clazz.class.name}]" unless clazz == @result[path].clazz
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
                cp::LXC => { "lxc" => true, "ruby" => true, "rubygems-integration" => [
                  '[ "$(gem list -i linux-lxc)" = "true" ] || gem install linux-lxc --no-ri --no-rdoc'
                ] },
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
              Construqt::Util.render(binding, "result_git_add.sh.erb")
            end

            def setup_ntp(host)
              ["cp /usr/share/zoneinfo/#{host.time_zone || host.region.network.ntp.get_timezone} /etc/localtime"]
            end

            def sh_is_opt_set
              Construqt::Util.render(binding, "result_is_opt_set.sh.erb")
            end

            def sh_install_packages
              Construqt::Util.render(binding, "result_install_packages.sh.erb")
            end

            def write_file(host, fname, block)
              if host.files
                return [] if host.files.find do |file|
                  file.path == fname && file.kind_of?(Construqt::Resources::SkipFile)
                end
              end
              text = block.flatten.select{|i| !(i.nil? || i.strip.empty?) }.join("\n")
              return [] if text.strip.empty?
              Util.write_str(@host.region, text, @host.name, fname)
              gzip_fname = Util.write_gzip(@host.region, text, @host.name, fname)
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

            end

            def commit
              add(EtcNetworkIptables, etc_network_iptables.commitv4, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW4), "etc", "network", "iptables.cfg")
              add(EtcNetworkIptables, etc_network_iptables.commitv6, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW6), "etc", "network", "ip6tables.cfg")
              add(EtcNetworkInterfaces, etc_network_interfaces.commit, Construqt::Resources::Rights.root_0644, "etc", "network", "interfaces")
              @etc_network_vrrp.commit(self)
              ipsec_secret.commit
              ipsec_cert_store.commit

              Lxc.write_deployers(@host)
              out = ["#!/bin/bash", "ARGS=$@"]

              out << sh_is_opt_set
              out << sh_function_git_add
              out << sh_install_packages

              out << Construqt::Util.render(binding, "result_package_list.sh.erb")

              out << "grep -q '/var/lib/lxcfs' /root/construqt.git/info/exclude || \\"
              out << "  echo '/var/lib/lxcfs' >> /root/construqt.git/info/exclude"

              out << "if [ $(is_opt_set skip_mother) != found ]"
              out << "then"
              out << Construqt::Util.render(binding, "result_host_check.sh.erb")

              out << "[ $(is_opt_set skip_packages) != found ] && install_packages #{components_hash.keys.join(' ')}"

              out << Construqt::Util.render(binding, "result_git_init.sh.erb")

              out += setup_ntp(host)
              out += components_hash.values.select{|i| i.instance_of?(Array) }.flatten

              @result.each do |fname, block|
                if !block.clazz.respond_to?(:belongs_to_mother?) ||
                   block.clazz.belongs_to_mother?
                  out += write_file(host, fname, block)
                end
              end
              out << "fi"
              @result.each do |fname, block|
                if block.clazz.respond_to?(:belongs_to_mother?) && !block.clazz.belongs_to_mother?
                  out += write_file(host, fname, block)
                end
              end
              out += Lxc.deploy(@host)
              out += [Construqt::Util.render(binding, "result_git_commit.sh.erb")]
              Util.write_str(@host.region, out.join("\n"), @host.name, "deployer.sh")
            end
          end
        end
      end
    end
  end
end
