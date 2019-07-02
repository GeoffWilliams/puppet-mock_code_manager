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
  spec.homepage      = "https://github.com/GeoffWilliams/puppet-mock_code_manager"
  spec.license       = "Apache-2.0"


  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "excon", "0.64.0"

  spec.add_dependency "sinatra", "2.0.5"
  spec.add_dependency "webrick", "1.4.2"
  spec.add_dependency "rack", "2.0.7"
  spec.add_dependency "rugged", "~> 0.28.2"

end
