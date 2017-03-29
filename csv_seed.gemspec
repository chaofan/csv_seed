lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'csv_seed/version'

Gem::Specification.new do |spec|
  spec.name        = 'csv_seed'
  spec.version     = CsvSeed::VERSION
  spec.date        = '2016-12-14'
  spec.summary     = "Import csv tables to rails"
  spec.description = "Import csv data to projects which are dependant on ActiveRecord."
  spec.authors     = ["chaofan"]
  spec.email       = 'jiangchaofan@gmail.com'
  spec.files       = Dir.glob('lib/**/*.{rb}') +
                      Dir.glob('bin/*') +
                      %w[README.md]
  spec.homepage    = 'https://github.com/chaofan/csv_seed'
  spec.license     = 'MIT'

  if spec.respond_to?(:metadata)
  spec.metadata['allowed_push_host'] = "http://rubygems.com"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # spec.files         = `git ls-files -z`.split("\x0").reject do |f|
  #   f.match(%r{^(test|spec|features)/})
  # end

  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'thor', '~> 0.14'
  spec.add_dependency 'thor-rails', '~> 0.0.1'

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
