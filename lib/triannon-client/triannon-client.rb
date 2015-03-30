
module TriannonClient

  class TriannonClient

    @@config = nil

    attr_accessor :site

    def initialize
      # Configure triannon-app service
      @@config ||= ::TriannonClient.configuration
      @site = RestClient::Resource.new(
        @@config.host,
        :user => @@config.user,
        :password => @@config.pass,
        :open_timeout => 5,  #seconds
        :read_timeout => 20, #seconds
      )
    end

    # Delete an annotation
    # @param iri [String] HTTP URL for a triannon annotation
    # @response [true|false] true when successful
    def delete_annotation(iri)
      uri = RDF::URI.parse(iri)
      response = @site[uri.path].delete
      # HTTP DELETE response codes:
      # A successful response SHOULD be 200 (OK) if the response includes an
      # entity describing the status, 202 (Accepted) if the action has not yet
      # been enacted, or 204 (No Content) if the action has been enacted but the
      # response does not include an entity.
      [200, 202, 204].include? response.code
    end

    # @param oa [JSON-LD] a json-ld object with an open annotation context
    # @return response [RestClient::Response|nil]
    def post_annotation(oa)
      post_data = {
        "commit" => "Create Annotation",
        "annotation" => {"data" => oa}
      }
      response = nil
      tries = 0
      begin
        tries += 1
        response = @site["/annotations/"].post post_data, :content_type => :json
      rescue => e
        sleep 1*tries
        retry if tries < 3
        binding.pry if @@config.debug
        @@config.logger.error("Failed to POST annotation: #{e.message}")
      end
      return response
    end

    # Get a list of annotations
    # @param content_type [String] HTTP accept header value for content type negotiation
    # @response [RDF::Graph|RestClient::Response] RDF::Graph when content_type is not specified
    def get_annotations(content_type=nil)
      if content_type.nil?
        get("#{@site.url}/annotations")
      else
        get("/annotations", content_type)
      end
    end

    # Get an annotation (with a default annotation context)
    # @param id [String] String representation of an annotation URI
    # @param content_type [String] HTTP accept header value for content type negotiation
    # @response [RDF::Graph|RestClient::Response] RDF::Graph when content_type is not specified
    def get_annotation(id, content_type=nil)
      if content_type.nil?
        get("#{@site.url}/annotations/#{id}")
      else
        get("/annotations/#{id}", content_type)
      end
    end

    # Get an annotation with a IIIF context
    # @param id [String] String representation of an annotation URI
    # @param content_type [String] HTTP accept header value for content type negotiation
    # @response [RDF::Graph|RestClient::Response] RDF::Graph when content_type is not specified
    def get_iiif_annotation(id, content_type=nil)
      if content_type.nil?
        get("#{@site.url}/annotations/iiif/#{id}")
      else
        get("/annotations/iiif/#{id}", content_type)
      end
    end

    # Get an annotation with an open annotation context
    # @param id [String] String representation of an annotation URI
    # @param content_type [String] HTTP accept header value for content type negotiation
    # @response [RDF::Graph|RestClient::Response] RDF::Graph when content_type is not specified
    def get_oa_annotation(id, content_type=nil)
      if content_type.nil?
        get("#{@site.url}/annotations/oa/#{id}")
      else
        get("/annotations/oa/#{id}", content_type)
      end
    end


    private

    # GET annotations and annotation
    #
    # use HTTP Accept header with mime type to indicate desired
    # format ** default: jsonld ** also supports turtle, rdfxml, html
    # ** see https://github.com/sul-dlss/triannon/blob/master/app/controllers/triannon/annotations_controller.rb #show method for mime formats accepted
    #
    # JSON-LD context
    #
    # You can request IIIF or OA context for jsonld. You can use either of
    # these methods (with the correct HTTP Accept header):
    #
    # GET: http://(host)/annotations/iiif/(anno_id)
    # GET: http://(host)/annotations/(anno_id)?jsonld_context=iiif
    #
    # GET: http://(host)/annotations/oa/(anno_id)
    # GET: http://(host)/annotations/(anno_id)?jsonld_context=oa
    #
    # Note that OA (Open Annotation) is the default context if none is specified.

    def get(uri, content_type=nil)
      if content_type.nil?
        # try to get an RDF graph, let RDF.rb do content negotiation
        RDF::Graph.load(uri)
      else
        # content_type options should include: :html, :xml, :rdf, :json
        content_type = content_type.to_sym
        @site[uri].get({:accept => content_type})
      end
    end

  end

end

