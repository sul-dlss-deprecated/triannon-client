module TriannonClient
  class TriannonClient
    # Triannon may not support all content types in RDF::Format.content_types,
    # but the client code is more generic using this as a reasonable set; this
    # allows triannon to evolve support for anything supported by RDF::Format.
    CONTENT_ERROR = 'content_type not found in RDF::Format.content_types'
    CONTENT_TYPES = RDF::Format.content_types.keys

    JSONLD_TYPE = 'application/ld+json'
    PROFILE_IIIF = 'http://iiif.io/api/presentation/2/context.json'
    PROFILE_OA   = 'http://www.w3.org/ns/oa-context-20130208.json'
    CONTENT_TYPE_IIIF = "#{JSONLD_TYPE}; profile=\"#{PROFILE_IIIF}\""
    CONTENT_TYPE_OA   = "#{JSONLD_TYPE}; profile=\"#{PROFILE_OA}\""

    attr_reader :config
    attr_accessor :site
    attr_accessor :container

    # Initialize a new triannon client
    # All params are optional, the defaults are set in
    # the ::TriannonClient.configuration
    # @param host [String] HTTP URI for triannon server
    # @param user [String] Authorized username for access to triannon server
    # @param pass [String] Authorized password for access to triannon server
    # @param container [String] The container path on the triannon server
    def initialize(host=nil, user=nil, pass=nil, container=nil)
      # Configure triannon-app service
      @config = ::TriannonClient.configuration
      host ||= @config.host
      host.chomp!('/') if host.end_with?('/')
      user ||= @config.user
      pass ||= @config.pass
      @site = RestClient::Resource.new(
        host,
        user: user,
        password: pass,
        open_timeout: 5,
        read_timeout: 30
      )
      container ||= @config.container
      container = "/#{container}"  unless container.start_with?('/')
      container =  "#{container}/" unless container.end_with?('/')
      @container = @site[container]
    end

    # Delete an annotation
    # @param id [String] an annotation ID
    # @response [true|false] true when successful
    def delete_annotation(id)
      check_id(id)
      begin
        response = @container[id].delete
        # HTTP DELETE response codes: A successful response SHOULD be
        # 200 (OK) if the response includes an entity describing the status,
        # 202 (Accepted) if the action has not yet been enacted, or
        # 204 (No Content) if the action has been enacted but the response
        # does not include an entity.
        [200, 202, 204].include? response.code
      rescue RestClient::Exception => e
        response = e.response
        # If an annotation doesn't exist, consider the request a 'success'
        return true if [404, 410].include? response.code
        binding.pry if @config.debug
        @config.logger.error("Failed to DELETE annotation: #{id}, #{response.body}")
        false
      rescue => e
        binding.pry if @config.debug
        @config.logger.error("Failed to DELETE annotation: #{id}, #{e.message}")
        false
      end
    end

    # POST and open annotation to triannon; the response contains an ID
    # @param oa [JSON-LD] a json-ld object with an open annotation context
    # @return response [RestClient::Response|nil]
    def post_annotation(oa)
      post_data = {
        'commit' => 'Create Annotation',
        'annotation' => {'data' => oa}
      }
      response = nil
      tries = 0
      begin
        tries += 1
        # TODO: add Accept content type, somehow?
        response = @container.post post_data, :content_type => JSONLD_TYPE, :accept => JSONLD_TYPE
      rescue => e
        sleep 1*tries
        retry if tries < 3
        response = e.response
        binding.pry if @config.debug
        @config.logger.error("Failed to POST annotation: #{response.code}: #{response.body}")
      end
      return response
    end

    # Get annotations
    # @param content_type [String] HTTP mime type (defaults to 'application/ld+json')
    # @response [RDF::Graph] RDF::Graph of open annotations (can be empty on failure)
    def get_annotations(content_type=JSONLD_TYPE)
      check_content_type(content_type)
      begin
        response = @container.get({:accept => content_type})
        # TODO: switch yard for different response.code?
        # TODO: log a failure for a response.code == 404
        response2graph(response)
      rescue => e
        binding.pry if @config.debug
        @config.logger.error("Failed to GET annotations: #{e.message}")
        RDF::Graph.new # return an empty graph
      end
    end

    # Get an annotation (with a default annotation context)
    # @param id [String] String representation of an annotation ID
    # @param content_type [String] HTTP mime type (defaults to 'application/ld+json')
    # @response [RDF::Graph] RDF::Graph of the annotation (can be empty on failure)
    def get_annotation(id, content_type=JSONLD_TYPE)
      check_id(id)
      check_content_type(content_type)
      begin
        response = @container[id].get({:accept => content_type})
        # TODO: switch yard for different response.code?
        response2graph(response)
      rescue => e
        # response = e.response
        binding.pry if @config.debug
        @config.logger.error("Failed to GET annotation: #{id}, #{e.message}")
        RDF::Graph.new # return an empty graph
      end
    end

    # Get an annotation using a IIIF context
    # @param id [String] String representation of an annotation ID
    # @response [RDF::Graph] RDF::Graph of the annotation (can be empty on failure)
    def get_iiif_annotation(id)
      get_annotation(id, CONTENT_TYPE_IIIF)
    end

    # Get an annotation using an open annotation context
    # @param id [String] String representation of an annotation ID
    # @response [RDF::Graph] RDF::Graph of the annotation (can be empty on failure)
    def get_oa_annotation(id)
      get_annotation(id, CONTENT_TYPE_OA)
    end

    # Parse a Triannon response into an RDF::Graph
    # @param response [RestClient::Response] A RestClient::Response from Triannon
    # @response graph [RDF::Graph] An RDF::Graph instance
    def response2graph(response)
      unless response.is_a? RestClient::Response
        raise ArgumentError, 'response must be a RestClient::Response'
      end
      content_type = response.headers[:content_type]
      check_content_type(content_type)
      g = RDF::Graph.new
      begin
        format = RDF::Format.for(:content_type => content_type)
        format.reader.new(response) do |reader|
          reader.each_statement {|s| g << s }
        end
      rescue
        binding.pry if @config.debug
        @config.logger.error("Failed to parse response into RDF::Graph: #{e.message}")
      end
      g
    end

    # query an annotation graph to extract a URI for the first open annotation
    # @param graph [RDF::Graph] An RDF::Graph of an open annotation
    # @response uri [Array<RDF::URI>] An array of URIs for open annotations
    def annotation_uris(graph)
      raise ArgumentError, 'graph is not an RDF::Graph' unless graph.instance_of? RDF::Graph
      q = [:s, RDF.type, RDF::Vocab::OA.Annotation]
      graph.query(q).collect {|s| s.subject }
    end

    # extract an annotation ID from the URI
    # @param uri [RDF::URI] An RDF::URI for an annotation
    # @response id [String|nil] An ID for an annotation
    def annotation_id(uri)
      raise ArgumentError, 'uri is not an RDF::URI' unless uri.instance_of? RDF::URI
      path = uri.path.split(@config.container).last
      CGI::escape(path)
    end


    private

    def check_content_type(content_type)
      type = content_type.split(';').first # strip off any parameters
      raise ArgumentError, CONTENT_ERROR unless CONTENT_TYPES.include? type
    end

    def check_id(id)
      raise ArgumentError, 'ID must be a String' unless id.instance_of? String
      raise ArgumentError, 'Invalid ID' if id.nil? || id.empty?
    end

  end

end

