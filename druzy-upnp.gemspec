# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'druzy/upnp/version'

Gem::Specification.new do |spec|
  spec.name          = "druzy-upnp"
  spec.version       = Druzy::Upnp::VERSION
  spec.authors       = ["Jonathan Le Greneur"]
  spec.email         = ["jonathan.legreneur@free.fr"]

  spec.summary       = %q{A control point UPNP}
  spec.description   = %q{Discover and interact with upnp device}
  spec.homepage      = "https://github.com/druzy/ruby-druzy-upnp"
  spec.license       = "MIT"

  spec.files         = `find lib -type f`.split("\n")
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "nokogiri", ">=  1.6.7.2"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
