require_relative './lxc_network'

module Construqt
  module Flavour
    module Nixian
      module Services
        module Lxc
          class Service
            attr_reader :lxc_pkg

            def initialize
              @hosts = []
              @lxc_pkg = "lxc"
              # binding.pry
            end

            def lxc_pkg(pkg)
              # binding.pry
              @lxc_pkg = pkg
              self
            end

            def get_lxc_pkg
              @lxc_pkg
            end

          end

          class Container
            include Construqt::Util::Chainable

            include Construqt::Util::Chainable

            chainable_attr :recreate
            chainable_attr :restart
            chainable_attr :upgrade
            chainable_attr :update
            # chainable_attr :template
            chainable_attr :killstop
            chainable_attr :aa_profile_unconfined

            chainable_attr_value :release
            chainable_attr_value :template
            attr_reader :host, :ship


            def attach_host(host)
              @host = host
            end

            def attach_ship(host)
              @ship = host
            end

            def publish(ph, pc = nil)
              @publishes ||= {}
              @publishes[ph] = pc || ph
              self
            end

            def get_publishes
              @publishes
            end

            def map(h, d)
              @maps ||= {}
              @maps[h] = d
              self
            end

            def get_maps
              @maps || {}
            end

            # def self.write_deployers(host)
            #   Container.write_deployers(host, ->(h) { h.lxc_deploy }, Lxc,
            #                             Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::LXC),
            #                             ->(h) { ['/var', 'lib', 'lxc', "#{h.name}.deployer.sh"] })
            # end

            def self.package_list(host)
              _package_list(host).keys
            end

            def self._host_package_list(host, match, result_package_list)
              host.result.package_builder.list(host.result.results.values.map { |i| i.right.component }).each do |artefact|
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
              _host_package_list(host, match, result_package_list)
              if Container.i_ma_the_mother?(host)
                host.region.hosts.get_hosts.select do |h|
                  host.eq(h.mother)
                end.each do |h|
                  _host_package_list(h, [Packages::Package::MOTHER, Packages::Package::BOTH], result_package_list)
                end

              end

              result_package_list
            end


            def self.belongs_to_mother?
              false
            end

            def update_config(base_dir, key, value)
              right = Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::LXC)
              Construqt::Util.render(binding, 'lxc_update_config.sh.erb')
            end

            def reference_net_config(base_dir)
              right = Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::LXC)
              Construqt::Util.render(binding, 'lxc_update_network_config.sh.erb')
            end

            def templates(host)
              out = host.region.hosts.get_hosts.inject({}) do |ret, lxc|
                if lxc.mother == host.delegate &&
                   lxc.lxc_deploy && lxc.lxc_deploy.get_template
                  ret[lxc.lxc_deploy.get_template] ||= []
                  ret[lxc.lxc_deploy.get_template] << lxc
                end

                ret
              end

              # binding.pry if host.name == "ao-mother"
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
                  throw "diffrent releases on one template [#{hosts.map { |h| h.lxc_deploy.get_release }.join(':')}]"
                end

                ret
              end
            end

            def self.flavour(hosts)
              flavour = hosts.inject(nil) do |ret, h|
                if !ret && h.flavour.name
                  ret = h.flavour.name
                elsif ret && h.flavour.name != ret
                  throw 'diffrent releases on one template'
                end

                ret
              end
            end

            def self.get_release(hosts)
              releases = hosts.select(&:lxc_deploy).map do |h|
                h.lxc_deploy.get_release
              end.sort.uniq
              if releases.length > 1
                throw "a template must have the same releases #{releases.join(':')}"
              end

              releases.first
            end

            def self.create_template(name, hosts)
              lxc_base = File.join('/var', 'lib', 'lxc')
              package_list = merge_package_list(hosts).join(',')
              release = " -- --packages #{package_list}"
              release += " -r #{get_release(hosts)}" if get_release(hosts)

              [Construqt::Util.render(binding, 'lxc/lxc_create_template.sh.erb')]
            end

            def stop_lxc_container(host)
              quick_stop = killstop? ? ' -k' : ''
              # lxc stop works sometimes so we test it
              <<-EOF
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
                Construqt::Util.render(binding, 'lxc/lxc_deploy_clones.sh.erb')
              end.join("\n")
            end

            def deploy(host)
              # if this a mother
              # return [] unless Container.i_ma_the_mother?(host)
              [
                Construqt::Util.render(binding, 'lxc/lxc_deploy.sh.erb')
              ]
            end

            def find_lxc_used_interfaces(host)
              ret = host.region.hosts.get_hosts.select { |h| host.eq(h.mother) }.map do |lxc|
                lxc.interfaces.values.map do |iface|
                  # puts iface.name
                  if iface.cable && !iface.cable.connections.empty?
                    throw 'multiple connection cable are not allowed' if iface.cable.connections.length > 1
                    iface.cable.connections.first.iface.name
                  end
                end
              end.flatten.compact.sort.uniq
              # binding.pry
              ret
            end

            def deploy_standalone(host)
              base_dir = File.join('/var', 'lib', 'lxc', host.name)
              lxc_rootfs = File.join(base_dir, 'rootfs')
              release = " -- --packages $(bash #{File.dirname(base_dir)}/#{host.name}.deployer.sh package_list)"
              if get_release
                release += " -r #{get_release}"
              end
              Construqt::Util.render(binding, 'lxc/lxc_deploy_standalone.sh.erb')
            end

            def invocation_build_config_host(ship, context)
              result = context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)

              #binding.pry
              container = self
              attach_ship(ship)


              result.add(Docker, deploy_standalone(host),
                         Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DOCKER),
                         "var", "lib", "lxc", "construqt", host.name, "lxc-launch.sh")

              # binding.pry
              # result.add(Docker, Construqt::Util.render(binding, "docker_run_simple_container.sh.erb"),
              #            Construqt::Resources::Rights.root_0755(Construqt::Resources::Component::DOCKER),
              #            "var", "lib", "docker", "construqt", container.host.name, "docker_run.sh")

              # up_downer = context.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
              # up_downer.add(host, Taste::Container.new(container))
            end

            def invocation_commit(ship, context)
              dsrv = context.find_by_service_type(Construqt::Flavour::Nixian::Services::DeployerSh::Service)
              action = lambda {
                [
                  deploy(host)
                ].flatten.join("\n")
              }
              dsrv.service_producers.each do |i|
                i.srv_inst.on_post_exec(action)
              end
            end
          end

          class Action
            attr_reader :host, :result

            def initialize(host)
              @host = host
            end

            def activate(ctx)
              @context = ctx
            end

            def build_config_host # (host, service)
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              once_per_host_which_have_lxcs = false
              host.region.hosts.get_hosts.select { |h| host.eq(h.mother) }.each do |lxc|
                next unless lxc.services.has_type_of?(Lxc::Service)
                once_per_host_which_have_lxcs ||= LxcNetwork.create_lxc_network_patcher(result, host, lxc)
                networks = lxc.interfaces.values.map do |iface|
                  next unless iface.cable && !iface.cable.connections.empty?
                  # binding.pry
                  throw 'multiple connection cable are not allowed' if iface.cable.connections.length > 1
                  LxcNetwork.new(iface).link(iface.cable.connections.first.iface.name).name(iface.name)
                end.compact
                LxcNetwork.render(result, host, lxc, networks)
              end
            end
          end

          class OncePerHost
            attr_reader :host, :service, :networks
            def initialize
              @service = Service.new
              @networks = []
            end

            def activate(context)
              @context = context
            end

            def attach_host(host)
              @host = host
            end

            def add_service(service)
              # @service.from_json(@service.daemon_json.merge(service.daemon_json))
              # @service.docker_pkg(service.get_docker_pkg)
            end

            def add_network(network)
              @networks.push network
            end

            def i_ma_the_mother?(host)
              host.region.hosts.get_hosts.find { |h| host.eq(h.mother) }
            end

            def render(result, host, docker)
            end

            def build_config_host # (host, service)
              # binding.pry if @host.name == 'rt-reg02-figo-stage-8'
              packager = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Packager::OncePerHost)
              # binding.pry if @host.name == "clavator"
              packager.register(Construqt::Resources::Component::LXC).add(service.get_lxc_pkg)
              host.region.hosts.get_hosts.select { |h| @host.eq(h.mother) }.find do |lxc|
                lxc.services.by_type_of(Construqt::Flavour::Nixian::Services::Invocation::Service)
                  .find do |i|
                      i.implementation.is_a?(Container)
                  end
              end && packager.add_component(Construqt::Resources::Component::LXC)

              # result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)

              # if i_ma_the_mother?(@host)
              #   ess = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost)
              #   # binding.pry
              #   ess.get_drop_in('docker.service', 'use_daemon_json.conf') do |override|
              #     override.exec_start('')
              #     override.exec_start('/usr/bin/dockerd')
              #   end
              # else
              #   # binding.pry
              #   result.add(Docker, Construqt::Util.render(binding, 'docker_starter.sh.erb'),
              #              Construqt::Resources::Rights.root_0755,
              #              'root', 'docker-starter.sh')
              # end
            end

            def commit
              # binding.pry
              return unless i_ma_the_mother?(@host)
              # binding.pry if @host.name == "bdog"
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              # result.add(self, JSON.pretty_generate(@service.daemon_json),
              #            Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DOCKER),
              #            '/etc', 'docker', 'daemon.json')

              # def self.write_deployers(host, forme, clazz, rights, path_action)
              host.region.hosts.get_hosts.select { |h| @host.eq(h.mother) }.each do |lxc|
                next unless lxc.services.by_type_of(Construqt::Flavour::Nixian::Services::Invocation::Service)
                               .find do |i|
                              i.implementation.is_a?(Container)
                            end
                # next if lxc.
                fcont = Util.read_str!(host.region, lxc.name, 'deployer.sh')
                throw "the should be a #{lxc.name}.deployer.sh" unless fcont
                result.add(self, fcont,
                           Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DOCKER),
                           '/var', 'lib', 'lxc', "#{lxc.name}.deployer.sh").skip_git

              end
            end
          end

          class Factory
            attr_reader :machine
            def start(service_factory)
              @machine ||= service_factory.machine
                                          .service_type(Service)
                                          .result_type(OncePerHost)
                                          .depend(DeployerSh::Service)
                                          .depend(Result::Service)
                                          .depend(UpDowner::Service)
            end

            def produce(host, _srv_inst, _ret)
              Action.new(host)
            end
          end
        end
      end
    end
  end
end

# module Construqt
#   module Flavour
#     module Nixian
#       module Dialect
#         module Ubuntu
#           module Lxc
#
#
#             def self.write_deployers(host)
#               Container.write_deployers(host, lambda{|h| h.lxc_deploy }, Lxc,
#                     Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::LXC),
#                     lambda{|h| ["/var", "lib", "lxc", "#{h.name}.deployer.sh"]})
#             end

#
#             def self.package_list(host)
#               _package_list(host).keys
#             end

#
#             def self._host_package_list(host, match, result_package_list)
#               host.result.package_builder.list(host.result.results.values.map{|i| i.right.component }).each do |artefact|
#                 artefact.packages.values.each do |p|
#                   next unless match.include?(p.target)
#                   result_package_list[p.name] = artefact
#                 end
#               end
#             end

#
#             def self._package_list(host)
#               artefact_set = {}
#               result_package_list = {}
#               match = [Packages::Package::ME, Packages::Package::BOTH]
#               match << Packages::Package::MOTHER if Container.i_ma_the_mother?(host)
#               self._host_package_list(host, match, result_package_list)
#               if Container.i_ma_the_mother?(host)
#                 host.region.hosts.get_hosts.select do |h|
#                   host.eq(h.mother)
#                 end.each do |h|
#                   self._host_package_list(h, [Packages::Package::MOTHER, Packages::Package::BOTH], result_package_list)
#                 end

#               end

#               result_package_list
#             end

#
#             def self.commands(host)
#               cmds = {}
#               _package_list(host).values.each do |artefact|
#                 artefact.commands.each do |cmd|
#                   cmds[cmd] = artefact
#                 end

#               end

#               cmds.keys
#             end

#
#             def self.belongs_to_mother?
#               false
#             end

#
#             def self.update_config(base_dir, key, value)
#               right = Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::LXC)
#               Construqt::Util.render(binding, "lxc_update_config.sh.erb")
#             end

#
#             def self.reference_net_config(base_dir)
#               right = Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::LXC)
#               Construqt::Util.render(binding, "lxc_update_network_config.sh.erb")
#             end

#
#             def self.templates(host)
#               out = host.region.hosts.get_hosts.inject({}) do |ret, lxc|
#                 if lxc.mother == host.delegate &&
#                     lxc.lxc_deploy && lxc.lxc_deploy.get_template
#                   ret[lxc.lxc_deploy.get_template] ||= []
#                   ret[lxc.lxc_deploy.get_template] << lxc
#                 end

#                 ret
#               end

#               #binding.pry if host.name == "ao-mother"
#               out
#             end

#
#             def self.merge_package_list(hosts)
#               hosts.inject({}) do |ret, host|
#                 package_list(host).map do |package_name|
#                   ret[package_name] = nil
#                 end

#                 ret
#               end.keys
#             end

#
#
#
#             def self.release(hosts)
#               release = hosts.inject(nil) do |ret, h|
#                 if !ret && h.lxc_deploy.get_release
#                   ret = h.lxc_deploy.get_release
#                 elsif ret && !h.lxc_deploy.get_release.nil? && h.lxc_deploy.get_release != ret
#                   throw "diffrent releases on one template [#{hosts.map{|h|h.lxc_deploy.get_release}.join(":")}]"
#                 end

#                 ret
#               end

#             end

#
#             def self.flavour(hosts)
#               flavour = hosts.inject(nil) do |ret, h|
#                 if !ret && h.flavour.name
#                   ret = h.flavour.name
#                 elsif ret && h.flavour.name != ret
#                   throw "diffrent releases on one template"
#                 end

#                 ret
#               end

#             end

#
#             def self.get_release(hosts)
#               releases = hosts.select{ |h|
#                 h.lxc_deploy
#               }.map{ |h|
#                 h.lxc_deploy.get_release
#               }.sort.uniq
#               if releases.length > 1
#                 throw "a template must have the same releases #{releases.join(":")}"
#               end

#               releases.first
#             end

#
#             def self.create_template(name, hosts)
#               lxc_base = File.join("/var", "lib", "lxc")
#               package_list = merge_package_list(hosts).join(",")
#               release = " -- --packages #{package_list}"
#               if get_release(hosts)
#                 release += " -r #{get_release(hosts)}"
#               end

#               [Construqt::Util.render(binding, "lxc/lxc_create_template.sh.erb")]
#             end

#
#             def self.stop_lxc_container(host)
#               quick_stop = host.lxc_deploy.killstop? ? ' -k' : ''
#               # lxc stop works sometimes so we test it
#               return <<-EOF
#               while $(lxc-ls --running -1 | grep -q '^#{host.name}\s*$')
#               do
#                 echo 'Stopping #{host.name}'
#                 lxc-stop -n '#{host.name}'#{quick_stop}
#               done
#               EOF
#             end

#
#             def self.deploy_clones(name, hosts)
#               hosts.map do |host|
#                 Construqt.logger.debug "LXC Host #{host.name}"
#                 Construqt::Util.render(binding, "lxc/lxc_deploy_clones.sh.erb")
#               end.join("\n")
#             end

#
#             def self.deploy(host)
#               # if this a mother
#               return [] unless Container.i_ma_the_mother?(host)
#               [
#                 Construqt::Util.render(binding, "lxc/lxc_deploy.sh.erb")
#               ]
#             end

#
#             def self.find_lxc_used_interfaces(host)
#               ret = host.region.hosts.get_hosts.select {|h| host.eq(h.mother) }.map do |lxc|
#                 lxc.interfaces.values.map do |iface|
#                   #puts iface.name
#                   if iface.cable and !iface.cable.connections.empty?
#                     throw "multiple connection cable are not allowed" if iface.cable.connections.length > 1
#                     iface.cable.connections.first.iface.name
#                   else
#                     nil
#                   end

#                 end

#               end.flatten.compact.sort.uniq
#               #binding.pry
#               ret
#             end

#
#             def self.deploy_standalone(host)
#               base_dir = File.join('/var', 'lib', 'lxc', host.name)
#               lxc_rootfs = File.join(base_dir, 'rootfs')
#               release = " -- --packages $(bash #{File.dirname(base_dir)}/#{host.name}.deployer.sh package_list)"
#               if host.lxc_deploy.get_release
#                 release += " -r #{host.lxc_deploy.get_release}"
#               end

#
#               Construqt::Util.render(binding, "lxc/lxc_deploy_standalone.sh.erb")
#             end

#
#           end

#         end

#       end

#     end

#   end

# end
