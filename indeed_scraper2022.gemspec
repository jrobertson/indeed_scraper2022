Gem::Specification.new do |s|
  s.name = 'indeed_scraper2022'
  s.version = '0.2.0'
  s.summary = 'Attempts to scrape the indeed.com jobsearch results (1 page).'
  s.authors = ['James Robertson']
  s.files = Dir['lib/indeed_scraper2022.rb']
  s.add_runtime_dependency('nokorexi', '~> 0.7', '>=0.7.0')
  s.add_runtime_dependency('ferrumwizard', '~> 0.2', '>=0.2.2')
  s.signing_key = '../privatekeys/indeed_scraper2022.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/indeed_scraper2022'
  s.required_ruby_version = '>= 2.3.0'
end
