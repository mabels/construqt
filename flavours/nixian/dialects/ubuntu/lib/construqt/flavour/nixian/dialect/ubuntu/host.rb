require_relative './lxc_network'
require_relative './vagrant_file'

module Construqt
  module Flavour
    module Nixian
      module Dialect
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
              host.result.add(self, Construqt::Util.render(binding, "host_udev.erb"),
                Construqt::Resources::Rights.root_0644, "etc", "udev", "rules.d", "23-persistent-vnet.rules")
              # not cool but sysctl.d/...
              host.result.add(self, Construqt::Util.render(binding, "host_sysctl.erb"),
                Construqt::Resources::Rights.root_0644, "etc", "sysctl.conf")

              host.result.add(self, Construqt::Util.render(binding, "host_hosts.erb"),
                Construqt::Resources::Rights.root_0644, "etc", "hosts")

              host.result.add(self, host.name, Construqt::Resources::Rights.root_0644, "etc", "hostname")
              host.result.add(self, "# WTF resolvconf", Construqt::Resources::Rights.root_0644, "etc", "resolvconf", "resolv.conf.d", "orignal");
              resolv_conf = Construqt::Util.render(binding, "host_resolv_conf.erb")
              host.result.add(self, resolv_conf, Construqt::Resources::Rights.root_0644, "etc", "resolvconf", "resolv.conf.d", "base");
              host.result.add(self, resolv_conf, Construqt::Resources::Rights.root_0644, "etc", "resolv.conf")

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

              host.result.add(self, Construqt::Util.render(binding, "host_ssh.erb"),
                Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::SSH), "etc", "ssh", "sshd_config")
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
  end
end
