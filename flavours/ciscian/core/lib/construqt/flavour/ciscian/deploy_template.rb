module Construqt
  module Flavour
    class Ciscian
      class DeployTemplate
        def self.write_template(host, flavour, ip, user, _pass)
          template = Construqt::Util.render(binding, 'deploy_template.erb')
          Util.write_str(host.region, template, File.join(host.name, 'deploy.sh'))
        end
      end
    end
  end
end
