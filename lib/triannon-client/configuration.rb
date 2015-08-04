
module TriannonClient

  class Configuration

    attr_accessor :debug
    attr_accessor :logger
    attr_reader :log_file

    # Parameters for triannon server
    attr_accessor :host
    # attr_accessor :user # triannon doesn't support basic auth
    # attr_accessor :pass # triannon doesn't support basic auth

    # Parameters for triannon container
    attr_accessor :container
    attr_accessor :container_user
    attr_accessor :container_workgroups

    # Parameters for triannon client authentication
    attr_accessor :client_id
    attr_accessor :client_pass

    def initialize
      @debug = env_boolean('DEBUG')

      @host = ENV['TRIANNON_HOST'] || 'http://localhost:3000'
      # @user = ENV['TRIANNON_USER'] || '' # triannon doesn't support basic auth
      # @pass = ENV['TRIANNON_PASS'] || '' # triannon doesn't support basic auth

      # Parameters for triannon client authentication
      @client_id   = ENV['TRIANNON_CLIENT_ID'] || ''
      @client_pass = ENV['TRIANNON_CLIENT_PASS'] || ''

      # Parameters for triannon container
      @container = ENV['TRIANNON_CONTAINER'] || ''
      @container += '/' unless(@container.empty? || @container.end_with?('/'))
      @container_user = ENV['TRIANNON_CONTAINER_USER'] || ''
      @container_workgroups = ENV['TRIANNON_CONTAINER_WORKGROUPS'] || ''

      # logger
      begin
        log_file = ENV['TRIANNON_LOG_FILE'] || 'log/triannon_client.log'
        @log_file = File.absolute_path log_file
        FileUtils.mkdir_p File.dirname(@log_file) rescue nil
        log_dev = File.new(@log_file, 'w+')
      rescue
        log_dev = $stderr
        @log_file = 'STDERR'
      end
      log_dev.sync = true if @debug # skip IO buffering in debug mode
      @logger = Logger.new(log_dev, 'weekly')
      @logger.level = @debug ? Logger::DEBUG : Logger::INFO
    end

    def env_boolean(var)
      # check if an ENV variable is true, use false as default
      ENV[var].to_s.upcase == 'TRUE' rescue false
    end

  end

end

