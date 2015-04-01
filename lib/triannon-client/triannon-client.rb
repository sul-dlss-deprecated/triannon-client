
module TriannonClient

  class TriannonClient

    CONTENT_TYPE_IIIF = 'application/ld+json; profile="http://iiif.io/api/presentation/2/context.json"'
    CONTENT_TYPE_OA   = 'application/ld+json; profile="http://www.w3.org/ns/oa-context-20130208.json"'

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
    # @param id [String] an annotation ID
    # @response [true|false] true when successful
    def delete_annotation(id)
      begin
        response = @site["/annotations/#{id}"].delete
        # HTTP DELETE response codes:
        # A successful response SHOULD be 200 (OK) if the response includes an
        # entity describing the status, 202 (Accepted) if the action has not yet
        # been enacted, or 204 (No Content) if the action has been enacted but the
        # response does not include an entity.
        [200, 202, 204].include? response.code
      rescue => e
        binding.pry if @@config.debug
        @@config.logger.error("Failed to DELETE annotation: #{id}: #{e.response.code}, #{e.message}")
        false
      end
    end

    # POST and open annotation to triannon; the response contains an ID
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
        response = @site["/annotations/"].post post_data, :content_type => 'application/ld+json'
      rescue => e
        sleep 1*tries
        retry if tries < 3
        response = e.response
        binding.pry if @@config.debug
        @@config.logger.error("Failed to POST annotation: #{response.code}: #{response.body}")
      end
      return response
    end

    # GET annotations and annotation
    #
    # use HTTP Accept header with mime type to indicate desired
    # format ** default: jsonld ** also supports turtle, rdfxml, html
    # ** see https://github.com/sul-dlss/triannon/blob/master/app/controllers/triannon/annotations_controller.rb #show method for mime formats accepted
    #
    # Although triannon may not support them all, RDF::Format.content_types includes:
    # 'application/n-triples' =>  [RDF::NTriples::Format]
    # 'text/plain'            =>  [RDF::NTriples::Format]
    # 'application/n-quads'   =>  [RDF::NQuads::Format]
    # 'text/x-nquads'         =>  [RDF::NQuads::Format]
    # 'application/ld+json'   =>  [JSON::LD::Format]
    # 'application/x-ld+json' =>  [JSON::LD::Format]
    # 'application/rdf+json'  =>  [RDF::JSON::Format]
    # 'text/html'             =>  [RDF::RDFa::Format, RDF::RDFa::Lite, RDF::RDFa::HTML]
    # 'application/xhtml+xml' =>  [RDF::RDFa::XHTML]
    # 'image/svg+xml'         =>  [RDF::RDFa::SVG]
    # 'text/n3'               =>  [RDF::N3::Format, RDF::N3::Notation3]
    # 'text/rdf+n3'           =>  [RDF::N3::Format]
    # 'application/rdf+n3'    =>  [RDF::N3::Format]
    # 'application/rdf+xml'   =>  [RDF::RDFXML::Format, RDF::RDFXML::RDFFormat]
    # 'application/trig'      =>  [RDF::TriG::Format]
    # 'application/x-trig'    =>  [RDF::TriG::Format]
    # 'application/trix'      =>  [RDF::TriX::Format]
    # 'text/turtle'           =>  [RDF::Turtle::Format, RDF::Turtle::TTL]
    # 'text/rdf+turtle'       =>  [RDF::Turtle::Format]
    # 'application/turtle'    =>  [RDF::Turtle::Format]
    # 'application/x-turtle'  =>  [RDF::Turtle::Format]

    # Get annotations
    # @param content_type [String] HTTP mime type (defaults to 'application/ld+json')
    # @response [RDF::Graph] RDF::Graph of open annotations
    def get_annotations(content_type='application/ld+json')

      # TODO: triannon is responding with HTML, not json-ld
      # see https://github.com/sul-dlss/triannon/issues/117

      response = @site['/annotations'].get({:accept => content_type})
      # TODO: switch yard for different response.code?
      response2graph(response, content_type)
    end

    # Get an annotation (with a default annotation context)
    # @param id [String] String representation of an annotation ID
    # @param content_type [String] HTTP mime type (defaults to 'application/ld+json')
    # @response [RDF::Graph|nil] RDF::Graph of the annotation
    def get_annotation(id, content_type='application/ld+json')
      uri = "/annotations/#{id}"
      response = @site[uri].get({:accept => content_type})
      # TODO: switch yard for different response.code?
      response2graph(response, content_type)
    end

    # Get an annotation using a IIIF context
    # @param id [String] String representation of an annotation ID
    # @response [RDF::Graph|nil] RDF::Graph of the annotation
    def get_iiif_annotation(id)
      get_annotation(id, CONTENT_TYPE_IIIF)
    end

    # Get an annotation using an open annotation context
    # @param id [String] String representation of an annotation ID
    # @response [RDF::Graph|nil] RDF::Graph of the annotation
    def get_oa_annotation(id)
      get_annotation(id, CONTENT_TYPE_OA)
    end

    # Parse an open annotation response into an RDF::Graph
    # @param data [String] An open annotation in some serialized format
    # @param content_type [String] An HTTP accept type (defaults to 'rdf+xml')
    # @response graph [RDF::Graph] An RDF::Graph instance
    def response2graph(data, content_type='application/rdf+xml')
      g = RDF::Graph.new
      # TODO: will RDF::Format work with the 'profile' parameter?
      format = RDF::Format.for(:content_type => content_type)
      format.reader.new(data) do |reader|
        reader.each_statement {|s| g << s }
      end
      g
    end

    # query an annotation graph to extract a URI for the first open annotation
    # @param graph [RDF::Graph] An RDF::Graph of an open annotation
    # @response uri [RDF::URI|nil] A URI for an open annotation
    def annotation_uri(graph)
      q = [:s, RDF.type, RDF::Vocab::OA.Annotation]
      graph.query(q).collect {|s| s.subject }.first
    end

    # extract an annotation ID from the URI
    # @param uri [RDF::URI] An RDF::URI for an annotation
    # @response id [String|nil] An ID for an annotation
    def annotation_id(uri)
      uri.path.split('/').last
    end

  end

end

