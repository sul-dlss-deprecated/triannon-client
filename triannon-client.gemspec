# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = 'triannon-client'
  s.version     = '0.1.0'
  s.licenses    = ['Apache-2.0']
  s.platform    = Gem::Platform::RUBY

  s.authors     = ['Darren Weber',]
  s.email       = ['darren.weber@stanford.edu']

  s.homepage    = 'https://github.com/sul-dlss/triannon-client'
  s.summary     = 'A client for RESTful transactions with a triannon annotation server'
  s.description = 'A client for RESTful transactions with a triannon annotation server'

  s.required_rubygems_version = '>= 1.3.6'

  s.extra_rdoc_files = ['README.md', 'LICENSE']

  # Use ENV for config
  s.add_dependency 'dotenv'
  # HTTP and RDF clients
  s.add_dependency 'rest-client', '~> 1.7'
  s.add_dependency 'linkeddata', '~> 1.0'
  # Use pry for console and debugging
  s.add_dependency 'pry'
  s.add_dependency 'pry-doc'

  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-ctags-bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'

  s.files   = `git ls-files`.split($/)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files  = s.files.grep(%r{^(test|spec|features)/})

  dev_files = %w(.gitignore bin/console bin/ctags.rb bin/setup.sh bin/test.sh)
  dev_files.each {|f| s.files.delete f; s.executables.delete f; }

end

