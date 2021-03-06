
Gem::Specification.new do |s|
  s.name = 'child-process-manager'
  s.version = '0.1.4'

  s.authors = ['bcg', 'fsvehla','csturm']
  s.email = 'brenden.grace@gmail.com'
  s.date = "2011-03-29"

  s.description = 'child-process-manager'
  s.homepage = ''
  s.rubyforge_project = 'child-process-manager'

  s.files = Dir['lib/**/*']
  s.test_files = Dir['spec/**/*']

  s.bindir = 'bin'
  s.executables =  ['cpm']

  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]

  s.rubygems_version = '1.3.6'

  s.add_dependency('trollop', '>=  1')

  s.summary = 'child-process-manager'
end

