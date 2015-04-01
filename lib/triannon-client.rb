require 'dotenv'
Dotenv.load
# The pry dependency must be available when the client is configured to
# run in debug mode, where it will fall into a pry console for rescue blocks.
require 'pry'
require 'pry-doc'
# require rest client prior to linkeddata, so the latter can use it.
require 'rest-client'
# If a proxy is present, RestClient needs explicit configuration to use it.
# (The ruby stdlib http client will use a proxy automatically.)
RestClient.proxy = ENV['http_proxy'] unless ENV['http_proxy'].nil?
RestClient.proxy = ENV['HTTP_PROXY'] unless ENV['HTTP_PROXY'].nil?
require 'linkeddata'
require 'rdf-vocab'
require_relative 'triannon-client/configuration'
require_relative 'triannon-client/triannon-client'

module TriannonClient

  # configuration at the module level, see
  # http://brandonhilkert.com/blog/ruby-gem-configuration-patterns/

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end

end
