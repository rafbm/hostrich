# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hostrich/version'

Gem::Specification.new do |spec|
  spec.name          = 'hostrich'
  spec.version       = Hostrich::VERSION
  spec.authors       = ['Rafaël Blais Masson']
  spec.email         = ['rafbmasson@gmail.com']
  spec.description   = 'Hostrich is a Rack middleware that eases multi-domain web app development.'
  spec.summary       = 'Hostrich is a Rack middleware that eases multi-domain web app development.'
  spec.homepage      = 'http://github.com/rafBM/hostrich'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'rack'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
