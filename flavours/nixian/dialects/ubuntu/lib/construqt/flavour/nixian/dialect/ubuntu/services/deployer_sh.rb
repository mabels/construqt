

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Services
            class DeployerSh
            end

            class DeployerShFactory
              attr_reader :machine
              def initialize(service_factory)
                @machine = service_factory.machine
                  .service_type(DeployerSh)
                  .require(Construqt::Flavour::Nixian::Services::Result::Service)
              end

              def produce(host, srv_ins, ret)
                DeployerShAction.new(host)
              end

            end

            class DeployerShAction

              attr_reader :host
              def initialize(host)
                @host = host
              end

              def activate(ctx)
                @context = ctx
              end

              def sh_install_packages
                Construqt::Util.render(binding, 'result_install_packages.sh.erb')
              end

              def sh_is_opt_set
                Construqt::Util.render(binding, 'result_is_opt_set.sh.erb')
              end

              def sh_function_git_add
                Construqt::Util.render(binding, 'result_git_add.sh.erb')
              end

              def setup_ntp(host)
                zone = host.time_zone || host.region.network.ntp.get_timezone
                ["[ -f /usr/share/zoneinfo/#{zone} ] && cp /usr/share/zoneinfo/#{zone} /etc/localtime"]
              end


              def commit # (host, service)
                # binding.pry
                #Lxc.write_deployers(@host)
                #Docker.write_deployers(@host)
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

                # SERVICE out << Construqt::Util.render(binding, 'result_package_list.sh.erb')

                # SERVICE out << PackagerSh.offline_package(host)

                out << 'for i in $(seq 8)'
                out << 'do'
                out << "  [ -e /bin/systemctl ] && systemctl mask container-getty@\$i.service > /dev/null"
                out << 'done'

                out << 'if [ $(is_opt_set skip_mother) != found ]'
                out << 'then'
                out << Construqt::Util.render(binding, 'result_host_check.sh.erb')

                # SERVICES out << "[ $(is_opt_set skip_packages) != found ] && install_packages #{Lxc.package_list(@host).join(' ')}"

                out << Construqt::Util.render(binding, 'result_git_init.sh.erb')

                out += setup_ntp(host.delegate)
                # SERVICES out += Lxc.commands(host)

                result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)

                result.results.each do |fname, block|
                  if !block.clazz.respond_to?(:belongs_to_mother?) ||
                      block.clazz.belongs_to_mother?
                    out += result.write_file(host.delegate, fname, block)
                  end
                end

                out << 'fi'
                result.results.each do |fname, block|
                  if block.clazz.respond_to?(:belongs_to_mother?) && !block.clazz.belongs_to_mother?
                    out += result.write_file(host.delegate, fname, block)
                  end
                end

                # out += Lxc.deploy(@host)
                # out += Docker.deploy(@host)
                out += [Construqt::Util.render(binding, 'result_git_commit.sh.erb')]
                Util.write_str(host.region, out.join("\n"), host.name, 'deployer.sh')

              end
            end

          end
        end
      end
    end
  end
end
