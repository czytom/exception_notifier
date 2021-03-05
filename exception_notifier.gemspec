require File.expand_path('../lib/exception_notifier/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'exception_notifier'
  s.version = ExceptionNotifier::VERSION
  s.authors = ['Krzysztof Tomczyk']
  s.date = '2019-09-19'
  s.summary = 'Exception notification for Ruby apps'
  s.homepage = 'https://czytom.github.io/exception_notifier/'
  s.email = 'ktomczyk@ifirma.pl'
  s.license = 'MIT'

  s.required_ruby_version     = '>= 2.0'
  s.required_rubygems_version = '>= 1.8.11'

  s.files = `git ls-files`.split("\n")
  s.files -= `git ls-files -- .??*`.split("\n")
  s.test_files = `git ls-files -- test`.split("\n")
  s.require_path = 'lib'

  s.add_dependency('pony')
end
