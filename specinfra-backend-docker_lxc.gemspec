# encoding: UTF-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

# More info at http://guides.rubygems.org/specification-reference/

Gem::Specification.new do |s|
  s.name = 'specinfra-backend-docker_lxc'
  s.version = '0.3.0.dev'
  s.date = '2015-11-16'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Specinfra Docker LXC Backend'
  s.description =
    'Serverspec / Specinfra backend for Docker LXC execution driver.'
  s.license = 'Apache-2.0'
  s.authors = %(Xabier de Zuazo)
  s.email = 'xabier@zuazo.org'
  s.homepage = 'https://github.com/zuazo/specinfra-backend-docker_lxc'
  s.require_path = 'lib'
  s.files = %w(
    LICENSE
    Rakefile
    .yardopts
  ) + Dir.glob('*.md') + Dir.glob('lib/**/*')
  s.test_files = Dir.glob('{test,spec,features}/*')
  s.required_ruby_version = Gem::Requirement.new('>= 2.0.0')

  s.add_dependency 'specinfra', '~> 2.13'

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec-core', '~> 3.1'
  s.add_development_dependency 'rspec-expectations', '~> 3.1'
  s.add_development_dependency 'rspec-mocks', '~> 3.1'
  s.add_development_dependency 'coveralls', '~> 0.7'
  s.add_development_dependency 'simplecov', '~> 0.9'
  s.add_development_dependency 'should_not', '~> 1.1'
  s.add_development_dependency 'rubocop', '~> 0.35.0'
  s.add_development_dependency 'yard', '~> 0.8'
  s.add_development_dependency 'docker-api', '~> 1.22'
  s.add_development_dependency 'serverspec', '~> 2.24'
end
