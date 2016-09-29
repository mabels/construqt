require 'yaml'
module Construqt
    module Flavour
        module Nixian
            module Dialect
                module CoreOs
                    class Result
                        def initialize(host)
                            @ures = Construqt::Flavour::Nixian::Dialect::Ubuntu::Result.new(host)
                        end
                        def host
                          @ures.host
                        end
                        def add(block, digest, *path)
                          @ures.add(block, digest, *path)
                        end
                        def add_component(component)
                          @ures.add_component(component)
                        end
                        def etc_network_iptables
                          @ures.etc_network_iptables
                        end
                        def etc_network_interfaces
                          @ures.etc_network_interfaces
                        end

                        def write_cloud_config(deployer_sh)
                          # binding.pry
                          out = {}
                          akeys = host.region.users.get_authorized_keys(host.delegate)
                          out['ssh_authorized_keys'] = akeys
                          out['coreos'] = { }
                          out['write_files'] = [
                            {
                              "path"=> "/home/core/deployer.sh",
                              "permissions"=> "0600",
                              "owner"=> "root",
                              "content"=> IO.read(deployer_sh)
                            }
                          ]
                          Util.write_str(host.region, "#cloud-config\n\n"+YAML.dump(out), host.name, 'coreos-cloud-config')
                        end

                        def commit
                          add(Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::EtcNetworkIptables, @ures.etc_network_iptables.commitv4, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW4), 'etc', 'network', 'iptables.cfg')
                          add(Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::EtcNetworkIptables, @ures.etc_network_iptables.commitv6, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW6), 'etc', 'network', 'ip6tables.cfg')
                          add(Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::EtcNetworkInterfaces, @ures.etc_network_interfaces.commit, Construqt::Resources::Rights.root_0644, 'etc', 'network', 'interfaces')
                          #@ures.etc_network_vrrp.commit(self)

                          #Lxc.write_deployers(@host)
                          out = [
                            '#!/bin/bash',
                            'ARGS=$@',
                            'SCRIPT=$0',
                            'SCRIPTNAME=`basename $0`',
                            'SCRIPTPATH=`dirname $0`',
                            'CONSTRUQT_GIT=/home/core/construqt.git'
                          ]

                          out << @ures.sh_is_opt_set
                          out << @ures.sh_function_git_add
                          #out << sh_install_packages

                          #out << Construqt::Util.render(binding, 'result_package_list.sh.erb')

                          #out << offline_package

                          #out << 'for i in $(seq 8)'
                          #out << 'do'
                          #out << "  systemctl mask container-getty@\$i.service > /dev/null"
                          #out << 'done'
#
                          #out << 'if [ $(is_opt_set skip_mother) != found ]'
                          #out << 'then'
                          #out << Construqt::Util.render(binding, 'result_host_check.sh.erb')
#
#                          out << "[ $(is_opt_set skip_packages) != found ] && install_packages #{Lxc.package_list(@host).join(' ')}"
#
                          out << Construqt::Util.render(binding, 'result_git_init.sh.erb')

                          # out += @uressetup_ntp(host)
                          #out += Lxc.commands(@host)

                          @ures.results.each do |fname, block|
                            if !block.clazz.respond_to?(:belongs_to_mother?) ||
                                block.clazz.belongs_to_mother?
                              out += @ures.write_file(host, fname, block)
                           end
                          end
#
#                          out << 'fi'
#                          @results.each do |fname, block|
#                            if block.clazz.respond_to?(:belongs_to_mother?) && !block.clazz.belongs_to_mother?
#                              out += write_file(host, fname, block)
#                            end
#                          end

#                          out += Lxc.deploy(@host)
#                          out += [Construqt::Util.render(binding, 'result_git_commit.sh.erb')]
                          Util.write_str(host.region, out.join("\n"), host.name, 'deployer.sh')
                          write_cloud_config(Util.get_filename(host.region, host.name, 'deployer.sh'))
                        end

                    end
                end
            end
        end
    end
end
