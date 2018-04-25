$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'devise_security_extension/version'

Gem::Specification.new do |s|
  s.name        = 'devise_security_extension'
  s.version     = DeviseSecurityExtension::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.licenses    = ['MIT']
  s.summary     = 'Security extension for devise'
  s.email       = 'team@phatworx.de'
  s.homepage    = 'http://github.com/phatworx/devise_security_extension'
  s.description = 'An enterprise security extension for devise, '\
    'trying to meet industrial standard security demands for web applications.'
  s.authors     = ['Marco Scholl', 'Alexander Dreher']

  s.files         = `git ls-files`.split("\n") - %w(.gitignore .travis.yml .ruby-version)
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 1.9.3'
  s.extra_rdoc_files      = %w(LICENSE.txt README.md)

  s.add_dependency('activerecord', '>= 4.1.0', '< 5.2')
  s.add_dependency('devise', '>= 3.0.0', '< 5.0')
  s.add_dependency('ipaddress')

  s.add_development_dependency('appraisal')
  s.add_development_dependency('coveralls')
  s.add_development_dependency('minitest')
  s.add_development_dependency('mocha', '~> 1.1')
  s.add_development_dependency('pry')
  s.add_development_dependency('rails_email_validator')
  s.add_development_dependency('recaptcha')
  s.add_development_dependency('rubocop')
  s.add_development_dependency('sqlite3', '~> 1.3.10')
  s.add_development_dependency('webrat', '0.7.3')
end
