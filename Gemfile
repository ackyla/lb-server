source 'https://rubygems.org'
source 'http://gems.github.com'
# Distribute your app as a gem
# gemspec

# Server requirements
# gem 'thin' # or mongrel
# gem 'trinidad', :platform => 'jruby'

# Optional JSON codec (faster performance)
# gem 'oj'

# Project requirements
gem 'rake'

# Component requirements
gem 'bcrypt-ruby', :require => 'bcrypt'
gem 'slim'
gem 'activerecord', '>= 3.1', :require => 'active_record'
gem 'sqlite3'

# Test requirements
group :test do
  gem 'rspec'
  gem 'rack-test', :require => 'rack/test'
  gem 'json_expressions'
  gem 'factory_girl', '4.3.0'
end

# Padrino Stable Gem
gem 'padrino', '0.11.4'

# Or Padrino Edge
# gem 'padrino', :github => 'padrino/padrino-framework'

# Or Individual Gems
# %w(core gen helpers cache mailer admin).each do |g|
#   gem 'padrino-' + g, '0.11.3'
# end

gem 'mysql2'
gem 'memcached'
gem 'database_cleaner'

gem 'carrierwave', :require => %w(carrierwave carrierwave/orm/activerecord)
