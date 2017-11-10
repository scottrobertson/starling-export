# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'starling/export/version'

Gem::Specification.new do |spec|
  spec.name          = "starling-export"
  spec.version       = Starling::Export::VERSION
  spec.authors       = ["Scott Robertson"]
  spec.email         = ["scottymeuk@gmail.com"]

  spec.summary       = "Generate a QIF or CSV file from starlingbank.com transactions"
  spec.description   = spec.summary
  spec.homepage      = 'http://starlingbank.com'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "commander"
  spec.add_dependency "qif"
  spec.add_dependency "rest-client"
  spec.add_dependency "colorize"
end
