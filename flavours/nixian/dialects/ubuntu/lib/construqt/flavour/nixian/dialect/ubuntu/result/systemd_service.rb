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
              chainable_attr_value :type, "oneshot"
              chainable_attr_value :exec_start, ""
              chainable_attr_value :exec_stop, ""
              attr_reader :afters, :befores, :conflicts
              def initialize(result, name)
                # binding.pry
                @enable = true
                @command = "start"
                @name = name
                @result = result
                @entries = {}
                @befores = []
                @afters = []
                @requires = []
                @conflicts = []
                @wanted_bys = []
                #@default_dependencies = ['no']
                @alsos = []
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
