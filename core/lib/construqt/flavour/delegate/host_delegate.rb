module Construqt
  module Flavour
    module Delegate


      class HostDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::UNREF
        attr_reader :users, :bgps, :ipsecs, :interface_graph
        def initialize(host)
          #binding.pry
          #Construqt.logger.debug "HostDelegate.new(#{host.name})"
          self.delegate = host

          @ipsecs = []
          @bgps = []
          @users = host.users || host.region.users
          @interface_graph = Construqt::Graph.new
        end

        def fqdn
          region.network.fqdn(self.name)
        end

        def domain
          region.network.domain
        end

        # def interface_graph
        #   id = interfaces.values.map{|i| i.ident }.sort.join(":")
        #   unless @graphs[id]
        #     # binding.pry
        #     @graphs[id] = Construqt::Graph.build_interface_graph_from_host(self)
        #   end
        #   @graphs[id]
        # end

        # def inspect
        #   "@<#{self.class.name}:#{self.object_id} name=#{name} mother=#{mother.inspect}>"
        # end

        def spanning_tree
          self.delegate.spanning_tree
        end

        def docker_deploy
          self.delegate.docker_deploy
        end

        def lxc_deploy
          self.delegate.lxc_deploy
        end

        def vagrant_deploy
          self.delegate.vagrant_deploy
        end

        def mother
          if self.delegate.respond_to? :mother
            self.delegate.mother
          else
            false
          end
        end

        def get_groups
          if self.delegate.add_groups.instance_of? String
            self.delegate.add_groups = [ self.delegate.add_groups ]
          end
          self.delegate.add_groups || []
        end

        def has_interface_with_component?(cp)
          self.interfaces.values.find { |i| i.class::COMPONENT == cp }
        end

        def address
          my = Construqt::Addresses::Address.new(delegate.region.network)
          self.interfaces.values.each do |i|
            if i.address
              my.add_addr(i.address)
            end
          end

          my
        end

        def _ident
          #binding.pry
          "Host_#{self.name}"
        end

        def factory
          self.delegate.factory
        end

        def region
          self.delegate.region
        end

        def result
          self.delegate.result
        end

        def flavour
          self.delegate.flavour
        end

        def interfaces
          self.delegate.interfaces
        end

        def id=(id)
          self.delegate.id = id
        end

        def id
          self.delegate.id
        end

        def configip=(id)
          self.delegate.configip = id
        end

        def configip
          self.delegate.configip
        end

        def add_ipsec(ipsec)
          @ipsecs << ipsec
        end

        def add_bgp(bgp)
          @bgps << bgp
        end

        def commit
          #header_clazzes = {:host => self } # host class need also a header call
          #footer_clazzes = {:host => self } # host class need also a header call
          #self.interfaces.values.each do |iface|
          #  header_clazzes[iface.class.name] ||= iface if iface.delegate.respond_to? :header
          #  footer_clazzes[iface.class.name] ||= iface if iface.delegate.respond_to? :footer
          #end

          # self.interfaces do

          self.flavour.pre_clazzes do |key, clazz|
            self.region.flavour_factory.call_aspects("#{key}.header", self, nil)
            clazz.header(self) if clazz.respond_to? :header
          end

          self.region.flavour_factory.call_aspects("host.commit", self, nil)
          self.result.commit

          self.flavour.pre_clazzes do |key, clazz|
            self.region.flavour_factory.call_aspects("#{key}.footer", self, nil)
            clazz.footer(self) if clazz.respond_to? :footer
          end
        end
      end
    end
  end
end
