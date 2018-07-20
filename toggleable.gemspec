
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "toggleable/version"

Gem::Specification.new do |spec|
  spec.name          = "toggleable"
  spec.version       = Toggleable::VERSION
  spec.authors       = ["bukalapak"]
  spec.email         = ["product@bukalapak.com"]

  spec.summary       = 'Toggleable gem used for feature toggler using redis'
  spec.summary       = %q{Toggleable gem for feature toggler purposes}
  spec.description   = %q{Toggleable gem for feature toggler purposes.}
  spec.homepage      = 'https://github.com/bukalapak/toggleable'
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", ">= 4.0.0"
  spec.add_runtime_dependency "rest-client"
  spec.add_runtime_dependency "json"
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "simplecov", ">= 0.16.1"
  spec.add_development_dependency "redis", "~> 3.0"
  spec.add_development_dependency "dotenv", ">= 2.4.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "codecov"
end
