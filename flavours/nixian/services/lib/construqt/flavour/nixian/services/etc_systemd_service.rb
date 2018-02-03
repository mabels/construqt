module Construqt
  module Flavour
    module Nixian
      module Services
        module EtcSystemdService

          class SystemdService
            include Util::Chainable
            chainable_attr_value :description
            chainable_attr_value :name
            chainable_attr_value :command, "start"
            chainable_attr_value :type, "simple"
            chainable_attr_value :restart_sec
            attr_reader :afters, :befores, :conflicts, :drop_ins, :service
            def initialize(name, service = nil)
              # binding.pry
              @service = service # dropins
              @description = ""
              @enable = true
              @environments = []
              @command = "start"
              @skip_content = false
              @remain_after_exit = false
              @name = name
              @restart_sec = nil
              @entries = {}
              @exec_starts = []
              @exec_start_pres = []
              @exec_stops = []
              @exec_stop_posts = []
              @befores = []
              @afters = []
              @requires = []
              @conflicts = []
              @wanted_bys = []
              @restarts = []
              #@default_dependencies = ['no']
              @alsos = []
              @wantses = []
              @drop_ins = {}
              @default_dependencies = nil
              @system_disable_services = []
            end

            def system_disable_service(service)
              @system_disable_services.push(service)
              self
            end

            def system_disable_services
              @system_disable_services
            end

            def default_dependencies(v)
              @default_dependencies = v
              self
            end

            def disable
              @enable = false
              self
            end

            def is_drop_in?
              @service != nil
            end

            def drop_in(name, &block)
              drop_in = @drop_ins[name]
              unless drop_in
                @drop_ins[name] = drop_in = SystemdService.new(name, self)
                block.call(drop_in)
              end
              drop_in
            end

            def exec_start(a)
              @exec_starts << a
              self
            end

            def get_exec_starts(a)
              @exec_starts
            end

            def wants(a)
              @wantses << a
              self
            end

            def get_wantses(a)
              @wantes
            end

            def restart(a)
              #binding.pry
              @restarts << a
              self
            end

            def get_restarts(a)
              #binding.pry
              @restarts
            end

            def environment(a)
              @environments << a
              self
            end

            def get_environments(a)
              @environments
            end

            def exec_start_pre(a)
              @exec_start_pres << a
              self
            end

            def get_exec_start_pres(a)
              @exec_start_pres
            end

            def exec_stop(a)
              @exec_stops << a
              self
            end

            def get_exec_stops
              @exec_stops
            end

            def get_exec_stop_posts
              @exec_stop_posts
            end

            def exec_stop_post(a)
              @exec_stop_posts << a
              self
            end

            def get_skip_content
              @skip_content
            end

            def skip_content
              @skip_content = true
              self
            end

            def get_remain_after_exit
              @remain_after_exit
            end

            def remain_after_exit
              @remain_after_exit = true
              self
            end


            def enable
              @enable = true
              self
            end

            def disable
              @enable = false
              self
            end

            def is_enable
              @enable
            end

            def wanted_by(name)
              @wanted_bys << name
              self
            end

            def also(name)
              @alsos << name
              self
            end

            def after(name)
              @afters << name
              self
            end

            def requires(name)
              @requires << name
              self
            end

            def before(name)
              @befores << name
              self
            end

            def conflict(name)
              @conflicts << name
              self
            end

            def as_systemd_file
              #binding.pry unless @restarts.empty?
              Construqt::Util.render(binding, "systemd_service.erb")
            end

            def commit(result)
              name = @name
              if @service
                name = File.join("#{@service.get_name}.d", name)
              end
              unless @skip_content
                result.add(SystemdService, as_systemd_file,
                         Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::SYSTEMD),
                         'etc', 'systemd', 'system', name)
              end
              @drop_ins.values.each do |srv|
                srv.commit(result)
              end
            end
          end

          class OncePerHost
            attr_reader :services
            def initialize
              @services = {}
            end

            def activate(context)
              @context = context
              pbuilder = @context.find_instances_from_type Construqt::Flavour::Nixian::Services::Packager::OncePerHost
              pbuilder.register(Construqt::Resources::Component::SYSTEMD)
            end

            def get_drop_in(service, name, &block)
              srv = get(service) do |srv|
                srv.type("dropin")
                srv.disable.command(nil).skip_content
              end
              srv.drop_in(name) do |drop_in|
                block.call(drop_in)
              end
            end

            def get(name, &block)
              service = @services[name]
              unless service
                @services[name] = service = SystemdService.new(name)
                block && block.call(service)
              end
              service
            end

            def sanitary(result)
              get("construqt-sanitary.service") do |srv|
                do_start_stop = false
                result.add(self, Util.render(binding, 'etc_systemd_deployer_sh.erb'),
                  Construqt::Resources::Rights.root_0755,
                  "etc", "construqt", "construqt-sanitary.sh")
                srv.description("construqt sanitary")
                  .default_dependencies(false)
                  .after("sysinit.target")
                  .after("local-fs.target")
                  .before("basic.target")
                  .type("oneshot")
                  .exec_start("/bin/sh /etc/construqt/construqt-sanitary.sh")
                  .wanted_by("basic.target")
              end
            end

            def commit
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              sanitary(result)
              services.values.each do |service|
                service.commit(result)
              end
              dsrv = @context.find_by_service_type(Construqt::Flavour::Nixian::Services::DeployerSh::Service)
              action = lambda {
                do_start_stop = true
                Util.render(binding, 'etc_systemd_deployer_sh.erb')
              }
              dsrv.service_producers.each do |i|
                i.srv_inst.on_post_exec(action)
              end
            end
          end

          class Service
          end

          class Action
          end

          class Factory
            attr_reader :machine
            def start(service_factory)
              @machine ||= service_factory.machine
                .service_type(Service)
                .result_type(OncePerHost)
                .depend(Packages::Builder)
                .depend(DeployerSh::Service)
                .depend(Result::Service)
                .depend(UpDowner::Service)
            end

            def produce(host, srv_inst, ret)
              Action.new
            end
          end
        end
      end
    end
  end
end
