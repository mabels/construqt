module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Lxc


            def self.write_deployers(host)
              Container.write_deployers(host, lambda{|h| h.lxc_deploy }, Lxc,
                    Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::LXC),
                    lambda{|h| ["/var", "lib", "lxc", "#{h.name}.deployer.sh"]})
            end

            def self.package_list(host)
              _package_list(host).keys
            end

            def self._host_package_list(host, match, result_package_list)
              host.result.package_builder.list(host.result.results.values.map{|i| i.right.component }).each do |artefact|
                artefact.packages.values.each do |p|
                  next unless match.include?(p.target)
                  result_package_list[p.name] = artefact
                end
              end
            end

            def self._package_list(host)
              artefact_set = {}
              result_package_list = {}
              match = [Packages::Package::ME, Packages::Package::BOTH]
              match << Packages::Package::MOTHER if Container.i_ma_the_mother?(host)
              self._host_package_list(host, match, result_package_list)
              if Container.i_ma_the_mother?(host)
                host.region.hosts.get_hosts.select do |h|
                  host.eq(h.mother)
                end.each do |h|
                  self._host_package_list(h, [Packages::Package::MOTHER, Packages::Package::BOTH], result_package_list)
                end
              end
              result_package_list
            end

            def self.commands(host)
              cmds = {}
              _package_list(host).values.each do |artefact|
                artefact.commands.each do |cmd|
                  cmds[cmd] = artefact
                end
              end
              cmds.keys
            end

            def self.belongs_to_mother?
              false
            end

            def self.update_config(base_dir, key, value)
              right = Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::LXC)
              Construqt::Util.render(binding, "lxc_update_config.sh.erb")
            end

            def self.reference_net_config(base_dir)
              right = Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::LXC)
              Construqt::Util.render(binding, "lxc_update_network_config.sh.erb")
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
              #binding.pry if host.name == "ao-mother"
              out
            end

            def self.merge_package_list(hosts)
              hosts.inject({}) do |ret, host|
                package_list(host).map do |package_name|
                  ret[package_name] = nil
                end
                ret
              end.keys
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

            def self.get_release(hosts)
              releases = hosts.select{ |h|
                h.lxc_deploy
              }.map{ |h|
                h.lxc_deploy.get_release
              }.sort.uniq
              if releases.length > 1
                throw "a template must have the same releases #{releases.join(":")}"
              end
              releases.first
            end

            def self.create_template(name, hosts)
              lxc_base = File.join("/var", "lib", "lxc")
              package_list = merge_package_list(hosts).join(",")
              release = " -- --packages #{package_list}"
              if get_release(hosts)
                release += " -r #{get_release(hosts)}"
              end
              [Construqt::Util.render(binding, "lxc/lxc_create_template.sh.erb")]
            end

            def self.stop_lxc_container(host)
              quick_stop = host.lxc_deploy.killstop? ? ' -k' : ''
              # lxc stop works sometimes so we test it
              return <<-EOF
              while $(lxc-ls --running -1 | grep -q '^#{host.name}\s*$')
              do
                echo 'Stopping #{host.name}'
                lxc-stop -n '#{host.name}'#{quick_stop}
              done
              EOF
            end

            def self.deploy_clones(name, hosts)
              hosts.map do |host|
                Construqt.logger.debug "LXC Host #{host.name}"
                Construqt::Util.render(binding, "lxc/lxc_deploy_clones.sh.erb")
              end.join("\n")
            end

            def self.deploy(host)
              # if this a mother
              return [] unless Container.i_ma_the_mother?(host)
              [
                Construqt::Util.render(binding, "lxc/lxc_deploy.sh.erb")
              ]
            end

            def self.find_lxc_used_interfaces(host)
              ret = host.region.hosts.get_hosts.select {|h| host.eq(h.mother) }.map do |lxc|
                lxc.interfaces.values.map do |iface|
                  #puts iface.name
                  if iface.cable and !iface.cable.connections.empty?
                    throw "multiple connection cable are not allowed" if iface.cable.connections.length > 1
                    iface.cable.connections.first.iface.name
                  else
                    nil
                  end
                end
              end.flatten.compact.sort.uniq
              #binding.pry
              ret
            end

            def self.deploy_standalone(host)
              base_dir = File.join('/var', 'lib', 'lxc', host.name)
              lxc_rootfs = File.join(base_dir, 'rootfs')
              release = " -- --packages $(bash #{File.dirname(base_dir)}/#{host.name}.deployer.sh package_list)"
              if host.lxc_deploy.get_release
                release += " -r #{host.lxc_deploy.get_release}"
              end

              Construqt::Util.render(binding, "lxc/lxc_deploy_standalone.sh.erb")
            end

          end
        end
      end
    end
  end
end
