module Construqt

  class Hosts

    class Vagrant
      def net(net)
        @net = net
        self
      end
      def get_net
        @net
      end
      def auto_config(mode = false)
        @auto_config = mode
        self
      end
      def get_auto_config
        @auto_config
      end

      def ssh_host_port(port)
        @ssh_host_port = port
        self
      end
      def get_ssh_host_port
        @ssh_host_port
      end
    end

  end
end
