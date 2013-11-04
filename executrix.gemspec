# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'executrix/version'

Gem::Specification.new do |gem|
  gem.name        = 'executrix'
  gem.version     = Executrix::VERSION
  gem.authors     = ['Jorge Valdivia', 'Leif Gensert']
  gem.email       = ['jorge@valdivia.me', 'leif@propertybase.com']
  gem.homepage    = 'https://github.com/propertybase/executrix'
  gem.summary     = %q{Ruby support for the Salesforce Bulk API}
  gem.description = %q{This gem provides a super simple interface for the Salesforce Bulk API. It provides support for insert, update, upsert, delete, and query.}
  gem.license     = 'MIT'

  gem.rubyforge_project = 'executrix'

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_dependency 'rake'
  gem.add_dependency 'json'
  gem.add_dependency 'nori', '< 2.4'
  gem.add_dependency 'nokogiri', '< 1.7'
  gem.add_dependency 'rubyzip', '< 1.2'
  gem.add_development_dependency 'rspec', '< 2.15'
  gem.add_development_dependency 'webmock', '< 1.18'
  if RUBY_ENGINE == 'rbx'
    gem.add_dependency 'rubysl', '< 2.1'
    gem.add_development_dependency 'racc', '< 1.5'
    gem.add_development_dependency 'rubinius-coverage', '< 2.1'
  end
end