module Construqt
  module Flavour
    module Nixian
      module Services
        module EtcSystemdService

          class SystemdService
            include Util::Chainable
            chainable_attr_value :description, "unknown"
            chainable_attr_value :name
            chainable_attr_value :command, "start"
            chainable_attr_value :type, "simple"
            attr_reader :afters, :befores, :conflicts
            def initialize(name)
              # binding.pry
              @enable = true
              @command = "start"
              @skip_content = false
              @name = name
              @entries = {}
              @exec_starts = []
              @exec_stops = []
              @exec_stop_posts = []
              @befores = []
              @afters = []
              @requires = []
              @conflicts = []
              @wanted_bys = []
              #@default_dependencies = ['no']
              @alsos = []
            end

            def exec_start(a)
              @exec_starts << a
              self
            end

            def get_exec_starts(a)
              @exec_starts
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
              Construqt::Util.render(binding, "systemd_service.erb")
            end

            def commit(result)
              result.add(SystemdService, as_systemd_file,
                         Construqt::Resources::Rights.root_0644(Construqt::Flavour::Nixian::Dialect::Ubuntu::Systemd),
                         'etc', 'systemd', 'system', @name)
            end
          end

          class OncePerHost
            attr_reader :services
            def initialize
              @services = {}
            end

            def activate(context)
              @context = context
            end


            def get(name, &block)
              service = @services[name]
              unless service
                @services[name] = service = SystemdService.new(name)
                block && block.call(service)
              end
              service
            end

            def commit
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              services.values.each do |service|
                service.commit(result)
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
                .depend(Result::Service)
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
