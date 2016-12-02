require 'shellwords'
require 'net/http'
require 'json'
require 'date'

module Construqt
  module Flavour
    module Nixian
      module Services
        module Result
          class Service
          end

          class OncePerHost
            attr_reader :results, :host
            def initialize # (result_types, host)
              # @result_types = result_types
              @results = {}
              # @ipsec_secret = Ipsec::IpsecSecret.new(self)
              # @ipsec_cert_store = Ipsec::IpsecCertStore.new(self)
              # @service_factory = ServiceFactory.new
            end

            def attach_host(host)
              @host = host
            end

            def activate(context)
              @context = context
            end

            def start
              #@up_downer = up_downer.attach_result(self)
              #@package_builder = Result.create_package_builder(self)
            end

            #def etc_network_vrrp(ifname)
            #  @etc_network_vrrp.get(ifname)
            #end

            class ArrayWithRightAndClazz # < Array
              attr_accessor :right, :clazz
              def initialize(right, clazz)
                self.right = right
                self.clazz = clazz
                @lines = []
              end

              def empty?
                @lines.empty?
              end

              def skip_git?
                !!@skip_git
              end

              def skip_git
                @skip_git = true
              end

              def add(str)
                @lines.push(str)
              end

              def flatten
                @lines.flatten
              end
            end

            def add_component(component)
              @results[component] ||= ArrayWithRightAndClazz.new(Construqt::Resources::Rights.root_0644(component), component.to_sym)
            end

            def empty?(name)
              !(@results[name])
            end

            def add(clazz, block, right, *path)
              # binding.pry if path.first == ":unref"
              path = File.join(*path)
              throw "not a right #{path}" unless right.respond_to?('right') && right.respond_to?('owner')
              unless @results[path]
                @results[path] = ArrayWithRightAndClazz.new(right, clazz)
                # binding.pry
                # @results[path] << [clazz.xprefix(@host)].compact
              end

              throw "clazz missmatch for path:#{path} [#{@results[path].clazz.class.name}] [#{clazz.class.name}]" unless clazz.class.name == @results[path].clazz.class.name
              @results[path].add(block + "\n")
              @results[path]
            end

            def replace(clazz, block, right, *path)
              path = File.join(*path)
              replaced = !!@results[path]
              @results.delete(path) if @results[path]
              add(clazz, block, right, *path)
              replaced
            end

            def directory_mode(mode)
              mode = mode.to_i(8)
              0 != (mode & 0o6) && (mode = (mode | 0o1))
              0 != (mode & 0o60) && (mode = (mode | 0o10))
              0 != (mode & 0o600) && (mode = (mode | 0o100))
              "0#{mode.to_s(8)}"
            end

            def write_file(host, fname, block)
              if host.files
                return [] if host.files.find do |file|
                  file.path == fname && file.is_a?(Construqt::Resources::SkipFile)
                end
              end

              text = block.flatten.select { |i| !(i.nil? || i.strip.empty?) }.join("\n")
              return [] if text.strip.empty?
              Util.write_str(host.region, text, host.name, fname)
              gzip_fname = Util.write_gzip(host.region, text, host.name, fname)
              [
                File.dirname("/#{fname}").split('/')[1..-1].inject(['']) do |res, part|
                  res << File.join(res.last, part); res
                end.select { |i| !i.empty? }.map do |i|
                  "[ ! -d #{i} ] && mkdir #{i} && chown #{block.right.owner} #{i} && chmod #{directory_mode(block.right.right)} #{i}"
                end,
                "import_fname #{fname}",
                'base64 -d <<BASE64 | gunzip > $IMPORT_FNAME', Base64.encode64(IO.read(gzip_fname)).chomp, 'BASE64',
                "git_add #{['/' + fname, block.right.owner, block.right.right, block.skip_git?].map { |i| '"' + Shellwords.escape(i) + '"' }.join(' ')}"
              ]
            end

            def commit
              #up_downer.commit

              # etc_network_neigh.commit(self)
              #ipsec_secret.commit
              #ipsec_cert_store.commit

              binding.pry if @host.name == "fanout-de"
              @results.each do |fname, block|
                if !block.clazz.respond_to?(:belongs_to_mother?) ||
                    block.clazz.belongs_to_mother?
                  write_file(host, fname, block)
                end
              end

              @results.each do |fname, block|
                if block.clazz.respond_to?(:belongs_to_mother?) &&
                    !block.clazz.belongs_to_mother?
                  write_file(host, fname, block)
                end
              end

              #binding.pry if host.name == "fanout-de"
              #@ipsec_secret.commit
            end
          end

          class Action
          end

          class Factory
            attr_reader :machine
            def start(service_factory)
              # binding.pry
              @machine ||= service_factory.machine
                .service_type(Service)
                .result_type(OncePerHost)
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
