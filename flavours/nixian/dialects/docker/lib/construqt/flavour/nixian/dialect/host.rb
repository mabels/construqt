class Host
  attr_accessor :delegate, :region, :interfaces, :id, :configip
  attr_reader :users, :services, :flavour, :name, :files
  def initialize(cfg)
    @name = cfg['name']
    @files = cfg['files']
    @region = cfg['region']
    @flavour = cfg['flavour']
    @interfaces = cfg['interfaces']
    @services = cfg['services'] || []
    @users = []
  end

  def build_config(host, unused, node)
  end
end
