class RouteService
  attr_accessor :name, :rt
  def initialize(name, rt)
    self.name = name
    self.rt = rt
  end
end

#Services.add_renderer(Construqt::Flavour::Nixian::Dialect::Ubuntu::Vrrp::RouteService, RouteService)
