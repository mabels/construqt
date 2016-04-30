module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Ipsec
            class IpsecCertStore
              def initialize(result)
                @result = result
                @packages = {}
              end
              def add(package)
                @packages[package.name] ||= package
              end
              def unify_write(type, list)
                list.inject({}){|r, k| r[k.name] = k; r }.values.each do |k|
                  @result.add(self, k.content, Construqt::Resources::Rights.root_0600, "etc", "ipsec.d", type, k.name)
                end
              end
              def commit
                unify_write("private", @packages.values.map{|p| p.key })
                unify_write("certs", @packages.values.map{|p| p.cert })
                unify_write("cacerts", @packages.values.map{|p| p.cacerts }.flatten)
              end
            end
          end
        end
      end
    end
  end
end
