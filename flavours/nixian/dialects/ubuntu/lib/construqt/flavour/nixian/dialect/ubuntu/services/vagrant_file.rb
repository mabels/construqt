module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Services


            class VagrantFile
              def initialize(ctx, mother, service, child)
                @context = ctx
                @mother = mother
                @child = child
                @mother_service = service
                @child_service = child.services.has_type_of?(Construqt::Flavour::Nixian::Services::Vagrant::Service)
                @child_service ||= Construqt::Flavour::Nixian::Services::Vagrant::Service.new
                @links = []
              end

              class Link
                attr_reader :mother_if
                attr_reader :child_if
                def initialize(mother_if, child_if)
                  @mother_if = mother_if
                  @child_if = child_if
                end
              end

              def add_link(mother_if, child_if)
                @links << Link.new(mother_if, child_if)
              end

              def vfile_header
                # binding.pry
                Construqt::Util.render(binding, "vagrant_header.erb")
              end

              def vfile_network
                @links.map do |link|
                  if link.mother_if.vagrant && link.mother_if.vagrant.get_net
                    "config.vm.network 'public_network', "+
                      ":#{link.mother_if.vagrant.get_net} => '#{link.mother_if.description || link.mother_if.name}',"+
                      "auto_config: #{link.mother_if.vagrant.get_auto_config} "+
                      "# ->#{link.child_if.name}"
                  else
                    "# skip #{link.mother_if.name} => #{link.child_if.name}"
                  end
                end.join("\n")+"\n"
              end

              def vfile_ssh_port
                @links.select do |link|
                  link.child_if.vagrant && link.child_if.vagrant.get_ssh_host_port
                end.map do |link|
                  "config.vm.network :forwarded_port, guest: 22, host: #{link.child_if.vagrant.get_ssh_host_port}"
                end.join("\n")+"\n"
              end

              def vfile_footer
                Construqt::Util.render(binding, "vagrant_footer.erb")
              end

              def render
                return if @links.empty?
                result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
                result.add(self, vfile_header+vfile_network+vfile_ssh_port+vfile_footer,
                                   Construqt::Resources::Rights.root_0644,
                                   "var", "lib", "vagrant", @child.name, "Vagrantfile")
              end
            end
          end
        end
      end
    end
  end
end
