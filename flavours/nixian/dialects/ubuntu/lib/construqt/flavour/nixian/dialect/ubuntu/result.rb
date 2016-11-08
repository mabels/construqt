
require 'shellwords'
require 'net/http'
require 'json'
require 'date'

require_relative 'result/etc_network_vrrp'
require_relative 'result/etc_network_interfaces'
require_relative 'result/etc_network_iptables'
require_relative 'result/etc_conntrackd_conntrackd'
require_relative 'result/etc_systemd_netdev'
require_relative 'result/etc_systemd_network'
require_relative 'result/systemd_service'
require_relative 'ipsec/ipsec_secret'
require_relative 'ipsec/ipsec_cert_store'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            attr_reader :etc_network_interfaces, :etc_network_iptables, :etc_conntrackd_conntrackd
            attr_reader :ipsec_secret, :ipsec_cert_store, :host, :package_builder, :results
            attr_reader :etc_systemd_netdev, :etc_systemd_network
            def initialize(host)
              @host = host
              @etc_systemd_netdev = EtcSystemdNetdev.new
              @etc_systemd_network = EtcSystemdNetwork.new
              @etc_network_interfaces = EtcNetworkInterfaces.new(self)
              @etc_network_iptables = EtcNetworkIptables.new
              @etc_conntrackd_conntrackd = EtcConntrackdConntrackd.new(self)
              @etc_network_vrrp = EtcNetworkVrrp.new
              @ipsec_secret = Ipsec::IpsecSecret.new(self)
              @ipsec_cert_store = Ipsec::IpsecCertStore.new(self)
              @package_builder = Result.create_package_builder
              @results = {}
            end

            def self.create_package_builder
              cps = Packages::Builder.new
              cp = Construqt::Resources::Component
              cps.register(cp::UNREF).add('language-pack-en').add('language-pack-de')
                .add('git').add('aptitude').add('traceroute')
                .add('tcpdump').add('strace').add('lsof')
                .add('ifstat').add('mtr-tiny').add('openssl')
              cps.register('Construqt::Flavour::Delegate::DeviceDelegate')
              cps.register('Construqt::Flavour::Nixian::Dialect::Ubuntu::Wlan')
              cps.register(Construqt::Flavour::Nixian::Dialect::Ubuntu::Systemd)
              cps.register('Construqt::Flavour::Nixian::Dialect::Ubuntu::Bond').add('ifenslave')
              cps.register('Construqt::Flavour::Delegate::VlanDelegate').add('vlan')
              cps.register('Construqt::Flavour::Delegate::TunnelDelegate')
              cps.register('Construqt::Flavour::Nixian::Dialect::Ubuntu::Gre')
              cps.register('Construqt::Flavour::Delegate::GreDelegate')
              cps.register('Construqt::Flavour::Delegate::OpvnDelegate').add('openvpn')
              cps.register('Construqt::Flavour::Delegate::BridgeDelegate').add('bridge-utils')
              cps.register(cp::NTP).add('ntpd')
              cps.register(cp::USB_MODESWITCH).add('usb-modeswitch').add('usb-modeswitch-data')
              cps.register(cp::VRRP).add('keepalived')
              cps.register(cp::FW4).add('iptables').add('ulogd2')
              cps.register(cp::FW6).add('iptables').add('ulogd2')
              [
                cps.register('Construqt::Flavour::Delegate::IpsecVpnDelegate'),
                cps.register('Construqt::Flavour::Delegate::IpsecDelegate'),
                cps.register(cp::IPSEC)].each do |reg|
                reg.add('strongswan')
                  .add('strongswan-plugin-eap-mschapv2')
                  .add('strongswan-plugin-xauth-eap')
              end
              cps.register(cp::SSH).add('openssh-server')
              cps.register(cp::BGP).add('bird')
              cps.register(cp::OPENVPN).add('openvpn')
              cps.register(cp::DNS).add('bind9')
              cps.register(cp::RADVD).add('radvd')
              cps.register(cp::DNSMASQ).add('dnsmasq').cmd('update-rc.d dnsmasq disable')
              cps.register(cp::CONNTRACKD).add('conntrackd').add('conntrack')
              cps.register(cp::LXC).add('lxc').add('ruby').add('rubygems-integration')
              cps.register(cp::DOCKER).add('docker.io')
                .cmd('[ "$(gem list -i linux-lxc)" = "true" ] || gem install linux-lxc --no-ri --no-rdoc')
              cps.register(cp::DHCPRELAY).add('wide-dhcpv6-relay').add('dhcp-helper')
              cps.register(cp::WIRELESS).both('crda').both('iw').mother('linux-firmware')
                .add('wireless-regdb').add('wpasupplicant')
              Construqt::Flavour::Nixian::Dialect::Ubuntu::Services::FACTORY.keys.each do |srv|
                srv.respond_to?(:add_component) && srv.add_component(cps)
              end
              cps
            end

            def etc_network_vrrp(ifname)
              @etc_network_vrrp.get(ifname)
            end

            def add_component(component)
              @results[component] ||= ArrayWithRightAndClazz.new(Construqt::Resources::Rights.root_0644(component), component.to_sym)
            end

            def empty?(name)
              !(@results[name])
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
              # binding.pry if path.first == ":unref"
              path = File.join(*path)
              throw "not a right #{path}" unless right.respond_to?('right') && right.respond_to?('owner')
              unless @results[path]
                @results[path] = ArrayWithRightAndClazz.new(right, clazz)
                # binding.pry
                # @results[path] << [clazz.xprefix(@host)].compact
              end

              throw "clazz missmatch for path:#{path} [#{@results[path].clazz.class.name}] [#{clazz.class.name}]" unless clazz.class.name == @results[path].clazz.class.name
              @results[path] << block + "\n"
              @results[path]
            end

            def replace(clazz, block, right, *path)
              path = File.join(*path)
              replaced = !!@results[path]
              @results.delete(path) if @results[path]
              add(clazz, block, right, *path)
              replaced
            end

            def directory_mode(mode)
              mode = mode.to_i(8)
              0 != (mode & 0o6) && (mode = (mode | 0o1))
              0 != (mode & 0o60) && (mode = (mode | 0o10))
              0 != (mode & 0o600) && (mode = (mode | 0o100))
              "0#{mode.to_s(8)}"
            end

            def sh_function_git_add
              Construqt::Util.render(binding, 'result_git_add.sh.erb')
            end

            def setup_ntp(host)
              zone = host.time_zone || host.region.network.ntp.get_timezone
              ["[ -f /usr/share/zoneinfo/#{zone} ] && cp /usr/share/zoneinfo/#{zone} /etc/localtime"]
            end

            def sh_is_opt_set
              Construqt::Util.render(binding, 'result_is_opt_set.sh.erb')
            end

            def sh_install_packages
              Construqt::Util.render(binding, 'result_install_packages.sh.erb')
            end

            def write_file(host, fname, block)
              if host.files
                return [] if host.files.find do |file|
                  file.path == fname && file.is_a?(Construqt::Resources::SkipFile)
                end
              end

              text = block.flatten.select { |i| !(i.nil? || i.strip.empty?) }.join("\n")
              return [] if text.strip.empty?
              Util.write_str(@host.region, text, @host.name, fname)
              gzip_fname = Util.write_gzip(@host.region, text, @host.name, fname)
              [
                File.dirname("/#{fname}").split('/')[1..-1].inject(['']) do |res, part|
                  res << File.join(res.last, part); res
                end.select { |i| !i.empty? }.map do |i|
                  "[ ! -d #{i} ] && mkdir #{i} && chown #{block.right.owner} #{i} && chmod #{directory_mode(block.right.right)} #{i}"
                end,
                "import_fname #{fname}",
                'base64 -d <<BASE64 | gunzip > $IMPORT_FNAME', Base64.encode64(IO.read(gzip_fname)).chomp, 'BASE64',
                "git_add #{['/' + fname, block.right.owner, block.right.right, block.skip_git?].map { |i| '"' + Shellwords.escape(i) + '"' }.join(' ')}"
              ]
            end

            def find_cache_file(pkg, *paths)
              fname = nil
              my = paths.find do |path|
                fname = File.join(path, pkg['name'])
                ret = false
                if File.exist?(fname)
                  throw "unknown sum_type #{fname} #{pkg['sum_type']}" unless ['MD5Sum'].include?(pkg['sum_type'])
                  if Digest::MD5.file(fname).hexdigest.casecmp(pkg['sum'].downcase).zero?
                    pkg['fname'] = fname
                    # Construqt.logger.debug "Incache #{fname}"
                    ret = true
                  end
                end

                ret
              end

              my || Construqt.logger.debug("Misscache #{fname}")
              my
            end

            def fetch_action(queue, cache_path)
              Thread.new do
                while !queue.empty? && pkg = queue.pop
                  next if find_cache_file(pkg, '/var/cache/apt/archives', cache_path)
                  fname = File.join(cache_path, pkg['name'])
                  Construqt.logger.debug "Download from #{pkg['url']} => #{fname} #{pkg['sum']}"
                  uri = URI(pkg['url'])
                  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
                    res = http.request(Net::HTTP::Get.new(uri))
                    chk = Digest::MD5.hexdigest(res.body).downcase
                    if chk != pkg['sum'].downcase
                      throw "downloaded file #{pkg['url']} checksum missmatch #{pkg['sum']} != #{chk}"
                    end

                    FileUtils.mkdir_p(File.dirname(fname))
                    File.open(fname, 'w') { |file| file.write(res.body) }
                    pkg['fname'] = fname
                  end
                end
              end
            end

            def offline_package
              if @host.packager
                path = [ENV['HOME'] || './', '.construqt', 'package-cache']
                FileUtils.mkdir_p path
                cacheJd=ENV['JD']||DateTime.now.jd
                package_params = {
                  'dist' => 'ubuntu',
                  'arch' => @host.arch || 'amd64',
                  'version' => (@host.lxc_deploy && @host.lxc_deploy.get_release) || 'xenial',
                  'packages' => Lxc.package_list(@host)
                }
                cacheSha1Packages = Digest::SHA1.hexdigest(package_params['packages'].join(":"))
                cacheFname=File.join(*path, "#{cacheJd}-#{package_params['dist']}-#{package_params['arch']}-#{package_params['version']}-#{cacheSha1Packages}.tag")
                packages = nil
                unless File.exist?(cacheFname)
                  Construqt.logger.debug "Load Woko for: #{File.basename(cacheFname)}"

                  uri = URI('https://woko.construqt.net/')
                  req = Net::HTTP::Post.new(uri, initheader = { 'Content-Type' => 'application/json' })
                  req.body = package_params.to_json
                  res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
                    http.request(req)
                  end
                  packages = JSON.parse(res.body)
                  IO.write(cacheFname, res.body)
                  Dir.glob(File.join(File.dirname(cacheFname), "*.tag")).each do |fname|
                    jd,rest = File.basename(fname).split('-')
                    if jd.to_i <= cacheJd - 7
                      File.delete fname
                    end
                  end
                else
                  packages = JSON.parse(IO.read(cacheFname))
                  Construqt.logger.debug("Used cached Woko for: #{File.basename(cacheFname)}")
                end

                queue = Queue.new
                packages.each { |pkg| queue << pkg }
                cache_path = File.join(ENV['HOME'] || './', '.construqt', 'package-cache',
                                       "#{package_params['dist']}-#{package_params['version']}-#{package_params['arch']}")
                threads = Array.new([8, queue.size].min) do
                  fetch_action(queue, cache_path)
                end

                threads.each(&:join)

                var_cache_path = '/var/cache/apt/archives'

                chksum = Digest::SHA1.hexdigest(packages.map do |i|
                  "#{i['name']}:#{i['sum']}"
                end.sort.join("\n"))
                packager_fname = Util.get_filename(@host.region, @host.name, 'packager.sh')
                packager_checksum = File.exist?(packager_fname) && `sh #{packager_fname} version`.strip
                if chksum == packager_checksum
                  Construqt.logger.debug "Skip packager.sh generation #{packager_fname}"
                else
                  Construqt.logger.debug "Generate packager.sh #{packager_fname}"
                  Util.open_file(@host.region, @host.name, 'packager.sh') do |f|
                    # binding.pry
                    f.puts Construqt::Util.render(binding, 'packager.header.sh.erb')
                    packages.each do |pkg|
                      f.puts "echo -n ."
                      f.puts "base64 -d <<BASE64 > #{File.join(var_cache_path, pkg['name'])}"
                      f.puts Base64.encode64(IO.read(pkg['fname']))
                      f.puts "BASE64"
                    end

                    f.puts Construqt::Util.render(binding, 'packager.footer.sh.erb')
                  end
                end
              end

              [
                'if [ -f "$SCRIPTPATH/packager.sh" ]',
                'then',
                '  bash $SCRIPTPATH/packager.sh',
                'elif [ -f "packager.sh" ]',
                'then',
                '  bash packager.sh',
                'fi'
              ].join("\n")
            end

            def commit
              add(EtcNetworkIptables, etc_network_iptables.commitv4, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW4), 'etc', 'network', 'iptables.cfg')
              add(EtcNetworkIptables, etc_network_iptables.commitv6, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW6), 'etc', 'network', 'ip6tables.cfg')
              add(EtcNetworkInterfaces, etc_network_interfaces.commit, Construqt::Resources::Rights.root_0644, 'etc', 'network', 'interfaces')
              @etc_systemd_netdev.commit(self)
              @etc_systemd_network.commit(self)
              @etc_network_vrrp.commit(self)
              ipsec_secret.commit
              ipsec_cert_store.commit

              Lxc.write_deployers(@host)
              Docker.write_deployers(@host)
              out = [
                '#!/bin/bash',
                'ARGS=$@',
                'SCRIPT=$0',
                'SCRIPTNAME=`basename $0`',
                'SCRIPTPATH=`dirname $0`',
                'CONSTRUQT_GIT=/root/construqt.git'
              ]

              out << sh_is_opt_set
              out << sh_function_git_add
              out << sh_install_packages

              out << Construqt::Util.render(binding, 'result_package_list.sh.erb')

              out << offline_package

              out << 'for i in $(seq 8)'
              out << 'do'
              out << "  [ -e /bin/systemctl ] && systemctl mask container-getty@\$i.service > /dev/null"
              out << 'done'

              out << 'if [ $(is_opt_set skip_mother) != found ]'
              out << 'then'
              out << Construqt::Util.render(binding, 'result_host_check.sh.erb')

              out << "[ $(is_opt_set skip_packages) != found ] && install_packages #{Lxc.package_list(@host).join(' ')}"

              out << Construqt::Util.render(binding, 'result_git_init.sh.erb')

              out += setup_ntp(host)
              out += Lxc.commands(@host)

              @results.each do |fname, block|
                if !block.clazz.respond_to?(:belongs_to_mother?) ||
                    block.clazz.belongs_to_mother?
                  out += write_file(host, fname, block)
                end
              end

              out << 'fi'
              @results.each do |fname, block|
                if block.clazz.respond_to?(:belongs_to_mother?) && !block.clazz.belongs_to_mother?
                  out += write_file(host, fname, block)
                end
              end

              out += Lxc.deploy(@host)
              out += Docker.deploy(@host)
              out += [Construqt::Util.render(binding, 'result_git_commit.sh.erb')]
              Util.write_str(@host.region, out.join("\n"), @host.name, 'deployer.sh')
            end
          end
        end
      end
    end
  end
end
