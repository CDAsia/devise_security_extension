# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'devise_security_extension/version'

Gem::Specification.new do |s|
  s.name        = 'devise_security_extension'
  s.version     = DeviseSecurityExtension::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.licenses    = ['MIT']
  s.summary     = 'Security extension for devise'
  s.email       = 'team@phatworx.de'
  s.homepage    = 'http://github.com/phatworx/devise_security_extension'
  s.description = 'An enterprise security extension for devise, trying to meet industrial standard security demands for web applications.'
  s.authors     = ['Marco Scholl', 'Alexander Dreher']

  s.files         = `git ls-files`.split("\n") - %w(.gitignore .travis.yml .ruby-version)
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 1.9.3'
  s.extra_rdoc_files      = ['LICENSE.txt', 'README.md']

  s.add_dependency('devise', '>= 3.0.0', '< 6.0')
end

