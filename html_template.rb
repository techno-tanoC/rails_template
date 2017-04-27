gsub_file 'Gemfile', /gem 'turbolinks'\n/, ''
gsub_file 'Gemfile', /gem 'jquery-rails'\n/, ''

gem 'slim-rails'

gem_group :development do
  gem 'pry'
  gem 'pry-rails'
  gem 'annotate'
end

gem_group :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'guard-rspec', require: false
  gem 'database_rewinder'
  gem 'rspec-request_describer'
  gem 'json_spec'
end

run 'bundle install --path vendor/bundle'

generate 'rspec:install'

rails_command 'db:create'
rails_command 'db:migrate'

application do
  <<~'EOS'
    config.generators do |g|
      g.javascripts false
      g.stylesheets false
      g.helper false
      g.test_framework :rspec,
        fixture: true,
        controller_specs: false,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        request_specs: true
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end
  EOS
end

create_file 'Guardfile', <<~'EOS'
  guard :rspec, cmd: 'bundle exec rspec' do
    watch('spec/spec_helper.rb')                        { "spec" }
    watch('config/routes.rb')                           { "spec/routing" }
    watch('app/controllers/application_controller.rb')  { "spec/controllers" }
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r{^app/(.*)(\.erb|\.haml|\.slim)$})          { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
    watch(%r{^lib/(.+)\.rb$})                           { |m| "spec/lib/#{m[1]}_spec.rb" }
    watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
  end
EOS

remove_file 'app/views/layouts/application.html.erb'
create_file 'app/views/layouts/application.html.slim', <<~EOS
html
  head
    title
      | #{app_name}
      = stylesheet_link_tag    'application', media: 'all'
      = javascript_include_tag 'application'
      = csrf_meta_tags
  body
    = yield
EOS

create_file 'db/seeds.rb', <<~EOS, force: true
  require 'factory_girl'
  Dir[Rails.root.join('spec/factories/**/*.rb')].each { |f| require f }
  Rake::Task['db:migrate:reset'].invoke
EOS

insert_into_file 'spec/rails_helper.rb', <<EOS, after: 'RSpec.configure do |config|'

  config.include JsonSpec::Helpers
  RSpec.configuration.include RSpec::RequestDescriber, type: :request

	config.before :all do
		FactoryGirl.reload
	end

  config.before :suite do
    DatabaseRewinder.clean_all
  end

  config.after :each do
    DatabaseRewinder.clean
  end
EOS

# remove comments and empty lines
empty_line_pattern = /^\s*\n/
comment_line_pattern = /^\s*#.*\n/

gsub_file 'config/routes.rb', comment_line_pattern, ''
gsub_file 'config/routes.rb', empty_line_pattern, ''

gsub_file 'config/database.yml', comment_line_pattern, ''

gsub_file 'config/secrets.yml', comment_line_pattern, ''
gsub_file 'config/secrets.yml', empty_line_pattern, ''

gsub_file 'config/environments/development.rb', comment_line_pattern, ''
gsub_file 'config/environments/test.rb', comment_line_pattern, ''
gsub_file 'config/environments/production.rb', comment_line_pattern, ''

gsub_file 'spec/spec_helper.rb', comment_line_pattern, ''
gsub_file 'spec/rails_helper.rb', comment_line_pattern, ''

# git :init
# git add: '.'
# git commit: "-m 'first commit'"
