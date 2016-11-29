module Construqt
  module Flavour
    module Nixian
      module Dialect
        module CoreOs
          class VagrantFile < Construqt::Flavour::Nixian::Dialect::Ubuntu::Services::VagrantFile
            def initialize(ctx, mother, service, child)
              super(ctx, mother, service, child)
              if mother == child
                unless service.get_box_url
                  # binding.pry
                  service.box_url("https://storage.googleapis.com/"+
                  "#{mother.flavour.dialect.update_channel||"beta"}.release.core-os.net/"+
                  "amd64-usr/#{mother.flavour.dialect.image_version||"current"}/coreos_production_vagrant.json")
                end
              end
            end
          end
        end
      end
    end
  end
end
