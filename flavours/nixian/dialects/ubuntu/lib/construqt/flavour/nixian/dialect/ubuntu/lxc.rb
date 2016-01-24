module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Lxc
            def self.update_config(base_dir, key, value)
              ruby = []
              right = Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::LXC)
              ruby << "/etc/lxc/update_config #{base_dir}/config #{base_dir}/update.config.list #{key} #{value}"
              ruby << "for i in `cat #{base_dir}/update.config.list`"
              ruby << 'do'
              ruby << "  git_add /$i #{right.owner} #{right.right} false"
              ruby << 'done'
              ruby
            end

            def self.reference_net_config(base_dir)
              ruby = []
              right = Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::LXC)
              ruby << "cp #{base_dir}/../#{File.basename(base_dir)}.network.config #{base_dir}/network.config"
              ruby << "/etc/lxc/update_network_in_config #{base_dir}/config #{base_dir}/network.config #{base_dir}/update.config.list"
              ruby << "for i in `cat #{base_dir}/update.config.list`"
              ruby << 'do'
              ruby << "  git_add /$i #{right.owner} #{right.right} false"
              ruby << 'done'
              ruby
            end

            def self.templates(host)
              out = host.region.hosts.get_hosts.inject({}) do |ret, lxc|
                if lxc.mother == host.delegate &&
                    lxc.lxc_deploy && lxc.lxc_deploy.get_template
                  ret[lxc.lxc_deploy.get_template] ||= []
                  ret[lxc.lxc_deploy.get_template] << lxc
                end

                ret
              end

              #binding.pry
              out
            end

            def self.i_ma_the_mother?(host)
              host.region.hosts.get_hosts.find { |h| host.delegate == h.mother }
            end

            def self.merge_components_hash(hosts)
              hosts.inject({}) do |ret, host|
                ret.merge(host.result.components_hash)
              end
            end

            def self.write_deployers(host)
              return unless i_ma_the_mother?(host)
              host.region.hosts.get_hosts.select {|h| host.delegate == h.mother }.each do |lxc|
                host.result.add(lxc, Util.read_str(host.region, lxc.name, "deployer.sh"),
                                Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::LXC),
                                "/var", "lib", "lxc", "#{lxc.name}.deployer.sh").skip_git
              end

              templates(host).each do |name, hosts|
                #binding.pry
                host.result.add(host, (["!/bin/sh"]+
                                       host.result.sh_install_packages+
                                       ["install_packages #{merge_components_hash(hosts).keys.join(" ")}"]).join("\n"),
                Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::LXC),
                "var", "lib", "lxc", "#{name}.install_packages")
              end
            end

            def self.release(hosts)
              release = hosts.inject(nil) do |ret, h|
                if !ret && h.lxc_deploy.get_release
                  ret = h.lxc_deploy.get_release
                elsif ret && !h.lxc_deploy.get_release.nil? && h.lxc_deploy.get_release != ret
                  throw "diffrent releases on one template [#{hosts.map{|h|h.lxc_deploy.get_release}.join(":")}]"
                end

                ret
              end
            end

            def self.flavour(hosts)
              flavour = hosts.inject(nil) do |ret, h|
                if !ret && h.flavour.name
                  ret = h.flavour.name
                elsif ret && h.flavour.name != ret
                  throw "diffrent releases on one template"
                end

                ret
              end
            end

            def self.create_template(name, hosts)
              out = []
              lxc_base = File.join("/var", "lib", "lxc")
              release = release(hosts) ? " -- -r #{release(hosts)}" : ""
              if hosts.inject(false){ |ret, h| ret |= h.lxc_deploy.recreate? }
                out << "echo start LXC-RECREATE #{name}"
                out << "lxc-ls --running | grep -q '#{name}' && lxc-stop -n '#{name}' -k"
                out << "[ -d #{File.join(lxc_base, name, "rootfs")}/usr/share ] && lxc-destroy -f -n '#{name}'"
                out << "lxc-create -n '#{name}' -t #{flavour(hosts)}#{release}"
              else
                out << "echo start LXC-RESTART #{name}"
                out << "lxc-ls --running | grep -q '#{name}' && lxc-stop -n '#{name}' -k"
                out << "[ -d #{File.join(lxc_base, name, "rootfs")}/usr/share ] || lxc-create -n '#{name}' -t #{flavour(hosts)}#{release}"
              end

              out << "cp #{lxc_base}/#{name}.install_packages #{lxc_base}/#{name}/rootfs/root/#{name}install_packages"
              if hosts.inject(false){ |ret, h| ret |= h.lxc_deploy.update? }
                out << "chroot #{lxc_base}/#{name}/rootfs /bin/bash -c 'apt-get update'"
              end

              if hosts.inject(false){ |ret, h| ret |= h.lxc_deploy.upgrade? }
                out << "chroot #{lxc_base}/#{name}/rootfs /bin/bash -c 'apt-get -qq -y upgrade'"
              end

              out << "chroot #{lxc_base}/#{name}/rootfs /bin/bash /root/#{name}.install_packages"
              out
            end

            def self.stop_lxc_container(host)
              quick_stop = host.lxc_deploy.killstop? ? ' -k' : ''
              "lxc-ls --running | grep -q '#{host.name}' && lxc-stop -n '#{host.name}'#{quick_stop}"
            end

            def self.deploy_clones(name, hosts)
              out = []
              hosts.each do |host|
                out << "echo LXC clone from overlay:#{name} to #{host.name}"
                out << stop_lxc_container(host)
                lxc_root = File.join("/var", "lib", "lxc", host.name)
                out << "[ -d #{lxc_root}] && lxc-destroy -n #{host.name}"
                out << "lxc-clone -s -B overlayfs #{name} #{host.name}"
                out << "echo fix config of #{host.name} in #{lxc_root}"
                out += reference_net_config(lxc_root)
                if host.lxc_deploy.aa_profile_unconfined?
                  out += update_config(lxc_root, 'lxc.aa_profile', 'unconfined')
                end

                out << "lxc-execute -n #{host.name} --  /bin/bash -c 'cat > /root/deployer.sh' < #{lxc_root}/../#{host.name}.deployer.sh"
                out << "lxc-execute -n #{host.name} --  /bin/bash /root/deployer.sh"
              end

              out
            end

            def self.deploy(host)
              out = []
              out << '[ "true" = "$(. /etc/default/lxc-net && echo $USE_LXC_BRIDGE)" ] && echo USE_LXC_BRIDGE="false" >> /etc/default/lxc-net'
              # if this a mother
              return out unless i_ma_the_mother?(host)
              # find all templates
              templates(host).each do |name, hosts|
                out << "echo LXC create overlay:#{name} for [#{hosts.map{|h| h.name}.join(":")}]"
                out += create_template(name, hosts)
                out += deploy_clones(name, hosts)
              end

              # deploy standalones
              host.region.hosts.get_hosts.select { |h| h.lxc_deploy && host.delegate == h.mother }.each do |lxc|
                out += deploy_standalone(lxc)
              end

              out
            end

            def self.deploy_standalone(host)
              out = []
              out << "echo LXC container #{host.name}"
              base_dir = File.join('/var', 'lib', 'lxc', host.name)
              lxc_rootfs = File.join(base_dir, 'rootfs')
              release = ""
              if host.lxc_deploy.get_release
                release = " -- -r #{host.lxc_deploy.get_release}"
              end

              if host.lxc_deploy.recreate?
                out << "echo start LXC-RECREATE #{host.name}"
                out << stop_lxc_container(host)
                out << "[ -d #{lxc_rootfs}/usr/share] && lxc-destroy -f -n '#{host.name}'"
                out << "lxc-create -n '#{host.name}' -t #{host.flavour.name}#{release}"
              elsif host.lxc_deploy.restart?
                out << "echo start LXC-RESTART #{host.name}"
                out << stop_lxc_container(host)
                out << "[ -d #{lxc_rootfs}/usr/share ] || lxc-create -n '#{host.name}' -t #{host.flavour.name}#{release}"
              end
              out << "echo fix config of #{host.name} in #{lxc_rootfs}"
              out += reference_net_config(base_dir)
              if host.lxc_deploy.aa_profile_unconfined?
                out += update_config(base_dir, 'lxc.aa_profile', 'unconfined')
              end

              out << "lxc-execute -n #{host.name} --  /bin/bash -c 'echo #{host.name} > /etc/hostname'"
              out << "lxc-execute -n #{host.name} --  /bin/bash -c 'cat > /root/deployer.sh' < #{base_dir}/../#{host.name}.deployer.sh"
              out << "lxc-execute -n #{host.name} --  /bin/bash /root/deployer.sh"

              out << "lxc-start -d -n '#{host.name}'"
            end

          end
        end
      end
    end
  end
end
