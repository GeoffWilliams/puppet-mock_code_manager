# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mock_code_manager/version"

Gem::Specification.new do |spec|
  spec.name          = "mock_code_manager"
  spec.version       = MockCodeManager::VERSION
  spec.authors       = ["Geoff Williams"]
  spec.email         = ["geoff@geoffwilliams.me.uk"]

  spec.summary       = %q{A mock version of Puppet Code Manager}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "sinatra", "1.4.8"
  spec.add_dependency "webrick", "1.3.1"
  spec.add_dependency "rack", "1.6.8"

end
