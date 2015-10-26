module Construqt
  module Flavour
    module Ubuntu

      class VagrantFile
        def initialize(mother, child)
          @mother = mother
          @child = child
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
          return <<OUT
Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty32"
  config.vm.hostname = "#{@child.name}"
  config.vm.provider "virtualbox" do |v|
    v.name = "Vagrant-#{@child.name}"
  end
OUT
        end

        def vfile_network
          @links.map do |link|
            if link.mother_if.vagrant && link.mother_if.vagrant.get_net
              "config.vm.network 'public_network', "+
              ":#{link.mother_if.vagrant.get_net} => '#{link.mother_if.description || link.mother_if.name}',"+
              "auto_config: #{link.mother_if.vagrant.get_auto_config} "+
              "# ->#{link.child_if.name}"
            else
              "# skip #{link.mother_if} => #{link.child_if.name}"
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
          return <<OUT
  config.vm.provision :shell, :inline => "sudo echo #{@child.name} > /etc/hostname"
  config.vm.provision :file, source: "../../../../../#{@child.name}/deployer.sh", destination: "deployer.sh"
  config.vm.provision :shell, :inline => "sudo bash /home/vagrant/deployer.sh"
  config.vm.provision :shell, :inline => "sudo reboot"
end
OUT
        end

        def render
          return if @links.empty?
          @mother.result.add(self, vfile_header+vfile_network+vfile_ssh_port+vfile_footer,
                             Construqt::Resources::Rights.root_0644,
                             "var", "lib", "vagrant", @child.name, "VagrantFile")
        end
      end
    end
  end
end
