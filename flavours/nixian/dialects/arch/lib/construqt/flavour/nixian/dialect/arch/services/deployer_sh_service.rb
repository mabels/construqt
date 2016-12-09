
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Arch
          module Services
            module DeployerShService
              def self.create
                Construqt::Flavour::Nixian::Services::DeployerSh::Service.new
                  .on_install_packages(lambda{
                    Construqt::Util.render(binding, 'result_install_packages.sh.erb')
                  })
              end
            end
          end
        end
      end
    end
  end
end
