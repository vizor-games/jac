require_relative 'lib/jac/version'
Gem::Specification.new do |s|
  s.name        = 'jac'
  s.version     = Jac::VERSION.join('.')
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'Just Another Configuration Lib'
  s.description = 'Profile based configuration lib'
  s.authors     = ['ilya.arkhanhelsky']
  s.email       = 'ilya.arkhanhelsky@vizor-games.com'
  s.homepage    = 'https://github.com/vizor-games/jac'
  s.files       = Dir['lib/**/*']
  s.license     = 'MIT'
end
