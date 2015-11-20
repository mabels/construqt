# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'construqt/flavour/ciscian/version'

Gem::Specification.new do |spec|
  spec.name          = "construqt-flavour-ciscian"
  spec.version       = Construqt::Flavour::Ciscian::VERSION
  spec.authors       = ["Meno Abels"]
  spec.email         = ["meno.abels@construqt.me"]
  spec.summary       = %q{Construqt me}
  spec.description   = %q{Construqt me}
  spec.homepage      = "http://github.com/mabels/construqt"
  spec.license       = "Apache License Version 2.0, January 2004"

  spec.files         = `git ls-files -z`.split("\x0").select{|i| i.start_with?("lib/") }
#  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
#  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "construqt-core", "~> 0.8.4"
  spec.add_runtime_dependency "construqt-ipaddress", "~> 0.8.4"
  spec.add_development_dependency "rake", "~> 10.0"
end
