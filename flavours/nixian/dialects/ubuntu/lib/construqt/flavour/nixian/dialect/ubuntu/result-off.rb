
require 'shellwords'
require 'net/http'
require 'json'
require 'date'

require_relative 'result/etc_network_vrrp'
require_relative 'result/etc_network_interfaces'
# require_relative 'result/etc_network_iptables'
# require_relative 'result/etc_network_neigh'
require_relative 'result/etc_conntrackd_conntrackd'
require_relative 'result/etc_systemd_netdev'
require_relative 'result/etc_systemd_network'
require_relative 'result/systemd_service'
# require_relative 'ipsec/ipsec_secret'
# require_relative 'ipsec/ipsec_cert_store'
require_relative 'result/packager_sh'
# require_relative 'result/up_downer'
#require_relative 'result/up_downer_systemd_taste'
#require_relative 'result/up_downer_debian_taste'
#require_relative 'result/up_downer_flat_taste'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            #attr_reader :ipsec_secret, :ipsec_cert_store, :host, :package_builder, :results
            # attr_reader :up_downer, :etc_network_iptables, :etc_network_neigh
            attr_reader :results
            def initialize # (result_types, host)
              # @result_types = result_types
              @results = {}
              @host = host

              # @ipsec_secret = Ipsec::IpsecSecret.new(self)
              # @ipsec_cert_store = Ipsec::IpsecCertStore.new(self)
              # @service_factory = ServiceFactory.new
            end

            def start
              #@up_downer = up_downer.attach_result(self)
              #@package_builder = Result.create_package_builder(self)
            end

            # def up_downer
            #  @up_downer ||= @result_types.find_by_service_type(Construqt::Flavour::Nixian::Services::UpDowner)
            #  throw "up_downer should be there" unless @up_downer
            #  @up_downer
            #end

            def get_etc_network_vrrp
              @etc_network_vrrp
            end

            def self.create_package_builder(result)
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
              result.host.flavour.services.each do |srv|
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

            def write_file(host, fname, block)
              if host.files
                return [] if host.files.find do |file|
                  file.path == fname && file.is_a?(Construqt::Resources::SkipFile)
                end
              end

              text = block.flatten.select { |i| !(i.nil? || i.strip.empty?) }.join("\n")
              return [] if text.strip.empty?
              Util.write_str(host.region, text, host.name, fname)
              gzip_fname = Util.write_gzip(host.region, text, host.name, fname)
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

            def commit


              #up_downer.commit

              # etc_network_neigh.commit(self)
              #ipsec_secret.commit
              #ipsec_cert_store.commit

              @results.each do |fname, block|
                if !block.clazz.respond_to?(:belongs_to_mother?) ||
                    block.clazz.belongs_to_mother?
                  write_file(host, fname, block)
                end
              end
              @results.each do |fname, block|
                if block.clazz.respond_to?(:belongs_to_mother?) &&
                  !block.clazz.belongs_to_mother?
                  write_file(host, fname, block)
                end
              end


              #binding.pry if host.name == "fanout-de"
              #@ipsec_secret.commit

            end
          end
        end
      end
    end
  end
end
