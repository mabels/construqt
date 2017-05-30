
module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          ENTITIES = {}

          def self.add_taste(taste, entity, impl)
            taste[entity.name] ||= []
            if taste[entity.name].find{|i| i == impl}
              return
              # binding.pry
              # throw "taste #{entity.name} #{impl}"
            end
            taste[entity.name].push impl
          end

          def self.add(entity)
            add_taste(ENTITIES, entity, entity)
          end

        end
      end
    end
  end
end

Dir.glob(File.join(File.dirname(__FILE__), "entities", "*.rb")).each do |fname|
  require fname
  # add("hello_world".split('_').collect(&:capitalize).join)
end
