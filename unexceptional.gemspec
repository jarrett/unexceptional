Gem::Specification.new do |s|
  s.name         = 'unexceptional'
  s.version      = '0.0.2'
  s.date         = Time.now.strftime('%Y-%m-%d')
  s.summary      = 'Unexceptional'
  s.description  = 'Provides a Result class for more elegant, exception-free error handling. ' +
                   'Especially useful for processing input that could be invalid for many different reasons.'
  s.authors      = ['Jarrett Colby']
  s.email        = 'jarrett@madebyhq.com'
  s.homepage     = 'https://github.com/jarrett/unexceptional'
  s.files        = Dir.glob('lib/**/*')
  s.license      = 'MIT'
  
  s.add_development_dependency 'minitest', '~> 5'
  s.add_development_dependency 'minitest-reporters', '~> 1'
  s.add_development_dependency 'activerecord'
  s.add_development_dependency 'sqlite3', '~> 1'
  s.add_development_dependency 'rake'
end