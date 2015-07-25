require 'pry' # for debugging specs

require 'simplecov'
require 'coveralls'
SimpleCov.profiles.define 'triannon-client' do
  add_filter 'pkg'
  add_filter 'spec'
  add_filter 'vendor'
end
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start 'triannon-client'

# Ensure there are no ENV configuration values.
FileUtils.mv '.env', '.env_bak', force: true
config_keys = ENV.keys.select {|k| k =~ /TRIANNON/ }
config_keys.each {|k| ENV.delete k }
require 'triannon-client'
::TriannonClient.reset

require 'rspec'
RSpec.configure do |config|
end

require 'vcr'
cassette_ttl = 28 * 24 * 60 * 60  # 28 days, in seconds
VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
  c.default_cassette_options = {
    :record => :new_episodes,
    :re_record_interval => cassette_ttl
  }
  c.configure_rspec_metadata!
end

def triannon_config_no_auth
  ::TriannonClient.configure do |config|
    config.debug = false
    config.host = 'http://localhost:3000'
    config.user = ''
    config.pass = ''
    config.client_id = ''
    config.client_pass = ''
    config.container = '/annotations/foo'
    config.container_user = ''
    config.container_workgroups = ''
  end
end

def triannon_config_auth
  ::TriannonClient.configure do |config|
    config.debug = false
    config.host = 'http://localhost:3000'
    config.user = ''
    config.pass = ''
    config.client_id = 'clientA'
    config.client_pass = 'secretA'
    config.container = '/annotations/bar'
    config.container_user = 'rspec'
    config.container_workgroups = 'org:wg-A, org:wg-B'
  end
end
