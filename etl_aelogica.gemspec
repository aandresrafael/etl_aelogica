lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "etl_aelogica/version"

Gem::Specification.new do |spec|
  spec.name          = "etl_aelogica"
  spec.version       = EtlAelogica::VERSION
  spec.authors       = ["Andres Aguilar"]
  spec.email         = ["andres@thinkcerca.com"]

  spec.summary       = "Gem which serves as a client to the data source for etl exercise."
  spec.description   = "Write a longer description or delete this line."
  spec.homepage      = "https://www.linkedin.com/in/andres-rafael-aguilar-albores-67626b17"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = "Put your gem's public repo URL here."
  #spec.metadata["changelog_uri"] = "Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "light-service", "~> 0.12.0"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
