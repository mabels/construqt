# require_relative 'services/docker'
# require_relative 'services/lxc'
# require_relative 'services/docker'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Host #< OpenStruct
            attr_reader :mother, :users, :region, :name, :interfaces
            attr_reader :flavour, :docker_deploy, :lxc_deploy, :dns_server, :files
            attr_accessor :delegate, :id, :configip, :add_groups
            attr_accessor :services, :vagrant_deploy, :time_zone, :dialect
            def initialize(cfg)
              @mother = cfg['mother']
              @services = cfg['services']
              @users = cfg['users']
              @region = cfg['region']
              @name = cfg['name']
              @interfaces = cfg['interfaces']
              @dialect = cfg['dialect']
              @flavour = cfg['flavour']
              @docker_deploy = cfg['docker_deploy']
              @vagrant_deploy = cfg['vagrant_deploy']
              @lxc_deploy = cfg['lxc_deploy']
              @dns_server = cfg['dns_server']
              @files = cfg['files']
              @services = cfg['services']
              @time_zone = cfg['time_zone']
              add_groups = cfg['add_groups']
            end

            # def result
            #   if @result
            #     @result
            #   else
            #     @result = self.delegate.result_types.find_instances_from_type(Construqt::Flavour::Nixian::Dialect::Ubuntu::Result)
            #   end
            # end
            #
            # def up_downer
            #   if @up_downer
            #     @up_downer
            #   else
            #     @up_downer = self.delegate.result_types.find_instances_from_type(Construqt::Flavour::Nixian::UpDowner::OncePerHost)
            #   end
            # end


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

            def build_config(host, unused, node)
              # binding.pry
              result = self.delegate.result_types.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)

              result.add(self, Construqt::Util.render(binding, "host_udev.erb"),
                Construqt::Resources::Rights.root_0644, "etc", "udev", "rules.d", "23-persistent-vnet.rules")
              # not cool but sysctl.d/...
              result.add(self, Construqt::Util.render(binding, "host_sysctl.erb"),
                Construqt::Resources::Rights.root_0644, "etc", "sysctl.conf")

              result.add(self, Construqt::Util.render(binding, "host_hosts.erb"),
                Construqt::Resources::Rights.root_0644, "etc", "hosts")

              result.add(self, host.name, Construqt::Resources::Rights.root_0644, "etc", "hostname")
              result.add(self, "# WTF resolvconf", Construqt::Resources::Rights.root_0644, "etc", "resolvconf", "resolv.conf.d", "orignal");
              resolv_conf = Construqt::Util.render(binding, "host_resolv_conf.erb")
              result.add(self, resolv_conf, Construqt::Resources::Rights.root_0644, "etc", "resolvconf", "resolv.conf.d", "base");
              result.add(self, resolv_conf, Construqt::Resources::Rights.root_0644, "etc", "resolv.conf")

              #binding.pry
              Dns.build_config(host) if host.delegate.dns_server
              ykeys = []
              skeys = []
              host.region.users.all.each do |u|
                # ykeys << "#{u.name}:#{u.yubikey}" if u.yubikey
                skeys << "#{u.shadow}" if u.shadow
              end

              host.delegate.files && host.delegate.files.each do |file|
                next if file.kind_of?(Construqt::Resources::SkipFile)
                if result.replace(nil, file.data, file.right, *file.path)
                  Construqt.logger.warn("the file #{file.path} was overriden!")
                end
              end

              # host.delegate.services ||= []
              #
              # [Services::Lxc, Services::Docker, Services::Vagrant].each do |s|
              #   unless host.delegate.services.find{|i| i.kind_of?(s)}
              #     host.delegate.services.push s.new
              #   end
              # end
              # host.delegate.services.each do |service|
              #   # r = Services.get_renderer(service)
              #   host.flavour.services.find(service).build_config_host(host, service)
              # end

              #
              # #puts host.name
              # # binding.pry if host.name == "etcbind-1"
              # create_lxc_containers(host)
              # create_docker_containers(host)
              # create_vagrant_containers(host)
              # #create_systemd_startup(host)
              # #create_plain_network_startup(host)
              #
            end
          end
        end
      end
    end
  end
end
