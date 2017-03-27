lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'csv_seed/version'

Gem::Specification.new do |s|
  s.name        = 'csv_seed'
  s.version     = CsvSeed::VERSION
  s.date        = '2016-12-14'
  s.summary     = "Import csv tables to rails"
  s.description = "Import csv data to projects which are dependant on ActiveRecord."
  s.authors     = ["chaofan"]
  s.email       = 'jiangchaofan@gmail.com'
  s.files       = Dir.glob('lib/**/*.{rb}') +
                  %w[README.md]
  s.homepage    = 'https://github.com/chaofan/csv_seed'
  s.license     = 'MIT'

  s.add_dependency 'thor', '~> 0.14'
  s.add_dependency 'thor-rails', '~> 0.0.1'
end
