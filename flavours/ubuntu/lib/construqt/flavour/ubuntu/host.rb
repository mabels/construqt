require_relative './lxc_network'
require_relative './vagrant_file'

module Construqt
  module Flavour
    module Ubuntu
      class Host < OpenStruct
        def initialize(cfg)
          super(cfg)
        end


        def create_vagrant_containers(host)
          host.region.hosts.get_hosts.select {|h| host == h.mother }.each do |vagrant|
            vfile = VagrantFile.new(host, vagrant)
            vagrant.interfaces.values.map do |iface|
              if iface.cable and !iface.cable.connections.empty?
                vfile.add_link(iface.cable.connections.first.iface, iface)
              end
            end
            vfile.render
          end
        end

        def create_lxc_containers(host)
          once_per_host_which_have_lxcs = false
          host.region.hosts.get_hosts.select {|h| host == h.mother }.each do |lxc|
            once_per_host_which_have_lxcs ||= LxcNetwork.create_lxc_network_patcher(host, lxc)
            networks = lxc.interfaces.values.map do |iface|
              if iface.cable and !iface.cable.connections.empty?
                #binding.pry
                throw "multiple connection cable are not allowed" if iface.cable.connections.length > 1
                LxcNetwork.new(iface).link(iface.cable.connections.first.iface.name).name(iface.name)
              else
                nil
              end
            end.compact
            LxcNetwork.render(host, lxc, networks)
          end
        end

        def build_config(host, unused)


          host.result.add(self, <<UDEV, Construqt::Resources::Rights.root_0644, "etc", "udev", "rules.d", "23-persistent-vnet.rules")
# Construqt UDEV for container mtu
SUBSYSTEM=="net", ACTION=="add", KERNEL=="vnet*", ATTR{mtu}="#{host.interfaces.values.map { |iface| iface.mtu.to_i || 1500 }.max}"
UDEV
          host.result.add(self, <<SCTL, Construqt::Resources::Rights.root_0644, "etc", "sysctl.conf")
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
net.ipv4.vs.pmtu_disc=1

net.ipv6.conf.all.autoconf=0
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.all.forwarding=1

net.ipv6.conf.all.proxy_ndp=1
SCTL
          host.result.add(self, <<HOSTS, Construqt::Resources::Rights.root_0644, "etc", "hosts")
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1       #{host.name} #{host.region.network.fqdn(host.name)}
HOSTS
          host.result.add(self, host.name, Construqt::Resources::Rights.root_0644, "etc", "hostname")
          host.result.add(self, "# WTF resolvconf", Construqt::Resources::Rights.root_0644, "etc", "resolvconf", "resolv.conf.d", "orignal");
          host.result.add(self,
                          (host.region.network.dns_resolver.nameservers.ips.map{|i| "nameserver #{i.to_s}" }+
                           ["search #{host.region.network.dns_resolver.search.join(' ')}"]).join("\n"),
                          Construqt::Resources::Rights.root_0644, "etc", "resolv.conf")


          #binding.pry
          Dns.build_config(host) if host.delegate.dns_server
          ykeys = []
          skeys = []
          host.region.users.all.each do |u|
            ykeys << "#{u.name}:#{u.yubikey}" if u.yubikey
            skeys << "#{u.shadow}" if u.shadow
          end
          akeys = host.region.users.get_authorized_keys(host)

          #host.result.add(self, skeys.join(), Construqt::Resources::Rights.root_0644, "etc", "shadow.merge")
          host.result.add(self, akeys.join(), Construqt::Resources::Rights.root_0644, "root", ".ssh", "authorized_keys")
          host.result.add(self, ykeys.join("\n"), Construqt::Resources::Rights.root_0644, "etc", "yubikey_mappings")

          host.result.add(self, <<SSH , Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::SSH), "etc", "ssh", "sshd_config")
# Package generated configuration file
# See the sshd_config(5) manpage for details

# What ports, IPs and protocols we listen for
Port 22
# Use these options to restrict which interfaces/protocols sshd will bind to
#ListenAddress ::
#ListenAddress 0.0.0.0
Protocol 2
# HostKeys for protocol version 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
#Privilege Separation is turned on for security
UsePrivilegeSeparation yes

# Lifetime and size of ephemeral version 1 server key
KeyRegenerationInterval 3600
ServerKeyBits 1024

# Logging
SyslogFacility AUTH
LogLevel INFO

# Authentication:
LoginGraceTime 120
PermitRootLogin without-password
StrictModes yes

RSAAuthentication yes
PubkeyAuthentication yes
#AuthorizedKeysFile	%h/.ssh/authorized_keys

# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes
# For this to work you will also need host keys in /etc/ssh_known_hosts
RhostsRSAAuthentication no
# similar for protocol version 2
HostbasedAuthentication no
# Uncomment if you don't trust ~/.ssh/known_hosts for RhostsRSAAuthentication
#IgnoreUserKnownHosts yes

# To enable empty passwords, change to yes (NOT RECOMMENDED)
PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no

# Change to no to disable tunnelled clear text passwords
PasswordAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosGetAFSToken no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes

X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
#UseLogin no

#MaxStartups 10:30:60
#Banner /etc/issue.net

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
UsePAM yes
SSH
          host.delegate.files && host.delegate.files.each do |file|
            next if file.kind_of?(Construqt::Resources::SkipFile)
            if host.result.replace(nil, file.data, file.right, *file.path)
              Construqt.logger.warn("the file #{file.path} was overriden!")
            end
          end

          #puts host.name
          #binding.pry
          create_lxc_containers(host)
          create_vagrant_containers(host)
        end
      end
    end
  end
end
