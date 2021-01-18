# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "jekyll-json-feed"
  spec.version       = "1.0.0"
  spec.authors       = ["Colin Seymour"]
  spec.email         = ["lildood@gmail.com"]
  spec.summary       = "A Jekyll plugin to generate a JSON feed of your Jekyll posts"
  spec.homepage      = "https://github.com/lildude/jekyll-json-feed"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r!^bin/!) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r!^(test|spec|features)/!)
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", ">= 3.3", "< 5.0"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "13.0"
  spec.add_development_dependency "rspec", "3.10"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-jekyll"
end
