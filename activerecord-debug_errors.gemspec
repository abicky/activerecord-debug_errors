require_relative 'lib/activerecord/debug_errors/version'

Gem::Specification.new do |spec|
  spec.name          = "activerecord-debug_errors"
  spec.version       = ActiveRecord::DebugErrors::VERSION
  spec.authors       = ["abicky"]
  spec.email         = ["takeshi.arabiki@gmail.com"]

  spec.summary       = %q{An extension of activerecord to display useful debug logs on errors}
  spec.description   = %q{ActiveRecord::DebugErrors is an extension of activerecord to display useful debug logs on errors.}
  spec.homepage      = "https://github.com/abicky/activerecord-debug_errors"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", ">= 6", "< 7"
  spec.add_development_dependency "mysql2"
end
