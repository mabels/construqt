
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Ipsec
            attr_accessor :delegate, :other, :cfg, :interface
            attr_reader :host, :my, :other, :firewalls, :remote
            attr_reader :any, :transport_left, :transport_right
            attr_reader :leftsubnet, :sourceip, :auto
            def initialize(cfg)
              @host = cfg["host"]
              host.services.add(Construqt::Flavour::Nixian::Services::IpsecStrongSwan.new(self))
              @my = cfg["my"]
              @other = cfg["other"]
              @firewalls = cfg["firewalls"]
              @remote = cfg["remote"]
              @interface = cfg["interface"]
              @any = cfg["any"]
              @transport_left = cfg["transport_left"]
              @transport_right = cfg["transport_right"]
              @leftsubnet = cfg["leftsubnet"]
              @any = cfg["any"]
              @sourceip = cfg["sourceip"]
              @auto = cfg["auto"]
            end

            def build_config(host, service, node)
              #binding.pry
            end

          end
        end
      end
    end
  end
end
