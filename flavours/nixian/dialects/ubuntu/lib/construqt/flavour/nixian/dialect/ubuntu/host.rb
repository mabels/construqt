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

            def inspect
              "#<#{self.class.name}:#{"%x"%object_id} name=#{name}>"
            end

            def eq(oth)
              delegate.eq(oth)
            end

            def belongs_to
              return [mother] if mother
              []
            end

            def render_vagrant(host, vagrant)
                vfile = VagrantFile.new(host, vagrant)
                vagrant.interfaces.values.map do |iface|
                  if iface.cable and !iface.cable.connections.empty?
                    vfile.add_link(iface.cable.connections.first.iface, iface)
                  end
                end
                vfile.render
            end
            def create_vagrant_containers(host)
              host.region.hosts.get_hosts.select {|h| host.eq(h.mother) }.each do |vagrant|
                render_vagrant(host, vagrant)
              end
              render_vagrant(host, host)
            end

            def create_docker_containers(host)
              host.region.hosts.get_hosts.select {|h| host.eq(h.mother) }.each do |docker|
                next unless docker.docker_deploy
                Docker.render(host, docker)
              end
            end


            def create_lxc_containers(host)
              # binding.pry
              once_per_host_which_have_lxcs = false
              host.region.hosts.get_hosts.select {|h| host.eq(h.mother) }.each do |lxc|
                next unless lxc.lxc_deploy
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

            def create_systemd_startup(host)
              return # we need not this!
              #binding.pry
              #Graph.dump(host.interface_graph)
              host.interface_graph.flat.each do |iface_string|
                systemds = []
                iface_string.each_with_index do |inode, idx|
                  systemd = Result::SystemdService.new(host.result, "#{inode.ident}.service")
                        .description("#{inode.ident}")
                        .type("oneshot")
                        .exec_start("/bin/bash /etc/network/#{inode.ref.name}-up.iface")
                        .exec_stop("/bin/bash /etc/network/#{inode.ref.name}-down.iface")
                  if idx+1 == iface_string.length
                    #last
                    systemd.wanted_by("network.target")
                  else
                    systemd.wanted_by("#{iface_string[idx+1].ref.name}.service")
                  end
                  host.result.add(Result::SystemdService, systemd.as_systemd_file,
                    Construqt::Resources::Rights.root_0644,
                    'etc', 'systemd', 'construqt', systemd.get_name)
                  systemds.push systemd
                end
              end
              #host.result.add(Result::SystemdService, active.join("\n"),
              #/etc/systemd/system/
            end

            def create_plain_network_startup(host)
              ups = []
              downs = []
              host.interface_graph.flat.each do |iface_string|
                  chain = iface_string.map{|inode| inode.ref.name}.join(",")
                  ups.push("# up chain [#{chain}]")
                  iface_string.each do |inode|
                      ups.push("#{File.join("/etc", "network", "#{inode.ref.name}-up.sh")}")
                      downs.unshift("#{File.join("/etc", "network", "#{inode.ref.name}-down.sh")}")
                  end
                  ups.push("/sbin/iptables-restore /etc/network/iptables.cfg")
                  ups.push("/sbin/ip6tables-restore /etc/network/ip6tables.cfg")
                  downs.unshift("# down [#{chain}]")
              end
              host.result.add(self, (["#!/bin/sh"]+ups).join("\n"),
                  Construqt::Resources::Rights.root_0755,
                  "etc", "network", "network_up.sh")

              host.result.add(self, (["#!/bin/sh"]+downs).join("\n"),
                  Construqt::Resources::Rights.root_0755,
                  "etc", "network", "network_down.sh")
            end

            def build_config(host, unused, node)
              # binding.pry
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
              host.result.add(self, akeys.join("\n"), Construqt::Resources::Rights.root_0600, "root", ".ssh", "authorized_keys")
              unless ykeys.empty?
                host.result.add(self, ykeys.join("\n"), Construqt::Resources::Rights.root_0644, "etc", "yubikey_mappings")
              end

              host.result.add(self, Construqt::Util.render(binding, "host_ssh.erb"),
                Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::SSH), "etc", "ssh", "sshd_config")
              host.delegate.files && host.delegate.files.each do |file|
                next if file.kind_of?(Construqt::Resources::SkipFile)
                if host.result.replace(nil, file.data, file.right, *file.path)
                  Construqt.logger.warn("the file #{file.path} was overriden!")
                end
              end

              #puts host.name
              # binding.pry if host.name == "etcbind-1"
              create_lxc_containers(host)
              create_docker_containers(host)
              create_vagrant_containers(host)
              create_systemd_startup(host)
              create_plain_network_startup(host)

            end
          end
        end
      end
    end
  end
end
