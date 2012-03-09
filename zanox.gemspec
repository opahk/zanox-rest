Gem::Specification.new do |s|
  s.name        = 'zanox'
  s.version     = '0.1.1'
  s.date        = '2012-02-09'
  s.summary     = "This is a simple ruby wrapper around the Zanox REST API for reports"
  s.description = ""
  s.authors     = ["Frank Eckert"]
  s.email       = 'frank.ecker@donovo.org'
  s.files       = ["lib/zanox.rb"]
  s.add_dependency(%q<ruby-hmac>, [">= 0"])
end
