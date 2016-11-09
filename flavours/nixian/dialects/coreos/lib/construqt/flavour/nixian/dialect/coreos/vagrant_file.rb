module Construqt
  module Flavour
    module Nixian
      module Dialect
        module CoreOs
          class VagrantFile < Construqt::Flavour::Nixian::Dialect::Ubuntu::VagrantFile
            def initialize(mother, child)
              super(mother, child)
              if mother == child
                unless mother.vagrant_deploy.get_box_url
                  mother.vagrant_deploy.box_url("https://storage.googleapis.com/"+
                  "#{mother.delegate.update_channel||"beta"}.release.core-os.net/"+
                  "amd64-usr/#{mother.delegate.image_version||"current"}/coreos_production_vagrant.json")
                end
              end
            end
          end
        end
      end
    end
  end
end
