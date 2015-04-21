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

    def initialize
      # Configure triannon-app service
      @config = ::TriannonClient.configuration
      @site = RestClient::Resource.new(
        @config.host,
        user: @config.user,
        password: @config.pass,
        open_timeout: 5,
        read_timeout: 30
      )
    end

    # Delete an annotation
    # @param id [String] an annotation ID
    # @response [true|false] true when successful
    def delete_annotation(id)
      check_id(id)
      begin
        response = @site["/annotations/#{id}"].delete
        # HTTP DELETE response codes: A successful response SHOULD be
        # 200 (OK) if the response includes an entity describing the status,
        # 202 (Accepted) if the action has not yet been enacted, or
        # 204 (No Content) if the action has been enacted but the response
        # does not include an entity.
        [200, 202, 204].include? response.code
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
        response = @site["/annotations/"].post post_data, :content_type => JSONLD_TYPE, :accept => JSONLD_TYPE
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
        response = @site['/annotations'].get({:accept => content_type})
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
      uri = "/annotations/#{id}"
      begin
        response = @site[uri].get({:accept => content_type})
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
        @config.logger.error("Failed parse response into RDF::Graph: #{e.message}")
      end
      g
    end

    # query an annotation graph to extract a URI for the first open annotation
    # @param graph [RDF::Graph] An RDF::Graph of an open annotation
    # @response uri [RDF::URI|nil] A URI for an open annotation
    def annotation_uri(graph)
      raise ArgumentError, 'graph is not an RDF::Graph' unless graph.instance_of? RDF::Graph
      q = [:s, RDF.type, RDF::Vocab::OA.Annotation]
      graph.query(q).collect {|s| s.subject }.first
    end

    # extract an annotation ID from the URI
    # @param uri [RDF::URI] An RDF::URI for an annotation
    # @response id [String|nil] An ID for an annotation
    def annotation_id(uri)
      raise ArgumentError, 'uri is not an RDF::URI' unless uri.instance_of? RDF::URI
      uri.path.split('/').last
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

