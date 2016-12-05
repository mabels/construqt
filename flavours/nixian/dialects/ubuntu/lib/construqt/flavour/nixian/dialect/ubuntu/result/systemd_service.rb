module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result

            class SystemdService
              include Util::Chainable
              chainable_attr_value :description, "unknown"
              chainable_attr_value :name
              chainable_attr_value :command, "start"
              chainable_attr_value :type, "simple"
              attr_reader :afters, :befores, :conflicts
              def initialize(result, name)
                # binding.pry
                @enable = true
                @command = "start"
                @skip_content = false
                @name = name
                @result = result
                @entries = {}
                @exec_starts = []
                @exec_stops = []
                @exec_stop_posts = []
                @befores = []
                @afters = []
                @requires = []
                @conflicts = []
                @wanted_bys = []
		@restart_directives = []
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
              def restart_directives(a)
                @restart_directive << a
              end
              def restart_directive(a)
                @restart_directives << a
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

              def commit
                @result.add(SystemdService, as_systemd_file,
                  Construqt::Resources::Rights.root_0644,
                    'etc', 'systemd', 'system', @name)

              end
            end
          end
        end
      end
    end
  end
end
