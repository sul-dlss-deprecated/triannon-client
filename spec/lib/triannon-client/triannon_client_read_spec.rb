require 'spec_helper'

# ::TriannonClient::TriannonClient GET specs
# The GET requests do not require authentication.

describe 'TriannonClientREAD', :vcr do

  before :all do
    # create a new annotation and call all the response processing utils.
    @anno = create_annotation('TriannonClientREAD/create_annotation')
  end

  after :all do
    clear_annotations('TriannonClientREAD/clear_annotations')
  end

  let(:tc) {
    # triannon_config_auth
    TriannonClient::TriannonClient.new
  }

  def request_anno_with_content_type(content_type)
    expect_any_instance_of(RestClient::Resource).to receive(:get).with(hash_including(:accept => content_type) )
    tc.get_annotation(@anno[:id], content_type)
  end
  def gets_anno_with_content_type(content_type)
    graph = tc.get_annotation(@anno[:id], content_type)
    graph_contains_open_annotation(graph, @anno[:uris])
  end
  def cannot_get_anno_with_content_type(content_type)
    graph = tc.get_annotation(@anno[:id], content_type)
    graph_is_empty(graph)
  end

  context 'GET' do

    describe "#get_annotations" do
      it 'returns an RDF::Graph' do
        graph = tc.get_annotations
        graph_contains_statements(graph)
      end
      it 'returns an RDF::Graph that contains an AnnotationList' do
        graph = tc.get_annotations
        anno_list_uri = RDF::URI.parse('http://iiif.io/api/presentation/2#AnnotationList')
        result = graph.query([nil, nil, anno_list_uri])
        expect(result.size).to eql(1)
      end
      it 'returns an annotation list with an annotation created by a prior POST' do
        graph = tc.get_annotations
        graph_contains_open_annotation(graph, @anno[:uris])
      end
      it 'returns an EMPTY RDF graph for a 500 server response' do
        response = double
        allow(response).to receive(:is_a?).and_return(RestClient::Response)
        allow(response).to receive(:headers).and_return(jsonld_content)
        allow(response).to receive(:body).and_return(jsonld_oa)
        allow(response).to receive(:code).and_return(500)
        exception = RestClient::Exception.new(response)
        allow_any_instance_of(RestClient::Resource).to receive(:get).with(jsonld_accept).and_raise(exception)
        graph = tc.get_annotations
        graph_is_empty(graph)
      end
      it 'logs exceptions for RestClient::Exception' do
        response = double
        allow(response).to receive(:is_a?).and_return(RestClient::Response)
        allow(response).to receive(:headers).and_return(jsonld_content)
        allow(response).to receive(:body).and_return('get_exception')
        allow(response).to receive(:code).and_return(500)
        exception = RestClient::Exception.new(response)
        allow_any_instance_of(RestClient::Resource).to receive(:get).with(jsonld_accept).and_raise(exception)
        expect(TriannonClient.configuration.logger).to receive(:error).with(/get_exception/)
        tc.get_annotations
      end
      it 'logs exceptions' do
        exception = RuntimeError.new('get_exception')
        allow_any_instance_of(RestClient::Resource).to receive(:get).with(jsonld_accept).and_raise(exception)
        expect(TriannonClient.configuration.logger).to receive(:error).with(/get_exception/)
        tc.get_annotations
      end
    end

    describe "#get_iiif_annotation" do
      # the mime type is fixed for this method
      it 'requests an open annotation by ID, using a IIIF profile' do
        graph_contains_open_annotation(@anno[:graph], @anno[:uris])
        content_type = TriannonClient::TriannonClient::CONTENT_TYPE_IIIF
        expect(tc).to receive(:get_annotation).with(@anno[:id], content_type)
        tc.get_iiif_annotation(@anno[:id])
      end
      it 'returns an RDF::Graph of an open annotation' do
        graph = tc.get_iiif_annotation(@anno[:id])
        graph_contains_statements(graph)
        graph_contains_open_annotation(graph, @anno[:uris])
      end
    end

    describe "#get_oa_annotation" do
      # the mime type is fixed for this method
      it 'requests an open annotation by ID, using an OA profile' do
        graph_contains_open_annotation(@anno[:graph], @anno[:uris])
        content_type = TriannonClient::TriannonClient::CONTENT_TYPE_OA
        expect(tc).to receive(:get_annotation).with(@anno[:id], content_type)
        tc.get_oa_annotation(@anno[:id])
      end
      it 'returns an RDF::Graph of an open annotation' do
        graph = tc.get_oa_annotation(@anno[:id])
        graph_contains_statements(graph)
        graph_contains_open_annotation(graph, @anno[:uris])
      end
    end

    describe '#response2graph' do
      it 'accepts a RestClient::Response instance' do
        r = @anno[:response]
        expect{tc.response2graph(r)}.not_to raise_error
      end
      it 'raises ArgumentError when given nil' do
        expect{tc.response2graph(nil)}.to raise_error(ArgumentError)
      end
      it 'raises ArgumentError when given an empty String' do
        expect{tc.response2graph('')}.to raise_error(ArgumentError)
      end
      it 'returns an RDF::Graph' do
        expect(@anno[:graph]).to be_instance_of RDF::Graph
      end
    end

    describe "#annotation_uris" do
      it "returns an array of RDF::URI from an RDF::Graph of an annotation" do
        expect(@anno[:graph]).to be_instance_of RDF::Graph
        expect(@anno[:uris]).to be_instance_of Array
        expect(@anno[:uris]).not_to be_empty
        expect(@anno[:uris].first).to be_instance_of RDF::URI
      end
      it "returns an RDF::URI that is a valid URI" do
        expect(@anno[:uris].first).to match(/\A#{URI::regexp}\z/)
      end
    end

    describe "#annotation_id" do
      it "returns a String ID from the RDF::URI of an annotation" do
        expect(@anno[:uris].first).to be_instance_of RDF::URI
        expect(@anno[:id]).to be_instance_of String
      end
      it "returns a String ID that is not empty" do
        expect(@anno[:id]).to be_instance_of String
        expect(@anno[:id]).not_to be_empty
      end
    end

    describe "annotation by ID" do

      context 'using default content type' do

        it 'checks the annotation ID' do
          expect(tc).to receive(:check_id)
          graph = tc.get_annotation(@anno[:id])
          graph_contains_statements(graph)
        end
        it 'raises an argument error with a nil ID' do
          expect{tc.get_annotation(nil)}.to raise_error(ArgumentError)
        end
        it 'raises an argument error with an integer ID' do
          expect{tc.get_annotation(0)}.to raise_error(ArgumentError)
        end
        it 'raises an argument error with an empty string ID' do
          expect{tc.get_annotation('')}.to raise_error(ArgumentError)
        end
        it 'requests an open annotation by ID, using JSON-LD content' do
          jsonld = TriannonClient::TriannonClient::JSONLD_TYPE
          expect_any_instance_of(RestClient::Resource).to receive(:get).with(hash_including(:accept => jsonld) )
          # does not work using expect(tc.container).to receive(:get) etc.
          tc.get_annotation(@anno[:id])
        end
        it 'returns an RDF graph with a valid ID for an annotation on the server' do
          graph = tc.get_annotation(@anno[:id])
          graph_contains_open_annotation(graph, @anno[:uris])
        end
        it 'returns an EMPTY RDF graph with a valid ID for NO annotation on the server' do
          id = SecureRandom.uuid
          graph = tc.get_annotation(id)
          graph_is_empty(graph)
        end
        it 'returns an EMPTY RDF graph for a 500 server response' do
          response = double
          allow(response).to receive(:is_a?).and_return(RestClient::Response)
          allow(response).to receive(:headers).and_return(jsonld_content)
          allow(response).to receive(:body).and_return(jsonld_oa)
          allow(response).to receive(:code).and_return(500)
          exception = RestClient::Exception.new(response)
          allow_any_instance_of(RestClient::Resource).to receive(:get).with(jsonld_accept).and_raise(exception)
          graph = tc.get_annotation(@anno[:id])
          graph_is_empty(graph)
        end
        it 'logs exceptions' do
          response = double
          allow(response).to receive(:is_a?).and_return(RestClient::Response)
          allow(response).to receive(:headers).and_return(jsonld_content)
          allow(response).to receive(:body).and_return('get_exception')
          allow(response).to receive(:code).and_return(500)
          exception = RestClient::Exception.new(response)
          allow_any_instance_of(RestClient::Resource).to receive(:get).with(jsonld_accept).and_raise(exception)
          expect(TriannonClient.configuration.logger).to receive(:error).with(/get_exception/)
          tc.get_annotation('raise_get_exception')
        end
      end # using default content type

      context 'using custom content type' do
        # Content types could be supported for RDF::Format.content_types.keys,
        # but not all of them are supported.  The supported content types for
        # triannon are defined in
        # https://github.com/sul-dlss/triannon/blob/master/config/initializers/mime_types.rb
        # https://github.com/sul-dlss/triannon/blob/master/app/controllers/triannon/annotations_controller.rb
        # https://github.com/sul-dlss/triannon/blob/master/app/controllers/triannon/search_controller.rb
        # The default content type is "application/ld+json" and, at the time of
        # writing, triannon also supports:
        # turtle as:  ["application/x-turtle", "text/turtle"]
        # rdf+xml as: ["application/rdf+xml", "text/rdf+xml", "text/rdf"]
        # json as:    ["application/json", "text/x-json", "application/jsonrequest"]
        # xml as:     ["application/xml", "text/xml", "application/x-xml"]
        # html

        # The client supports any format in RDF::Format.content_types, so the
        # following are not included (as of July 2015):
        # "application/json"        => true,
        # "application/jsonrequest" => true,
        # "text/x-json"             => true,
        # "text/rdf+xml"            => true,
        # "text/rdf"                => true,
        # "application/xml"         => true,
        # "text/xml"                => true,
        # "application/x-xml"       => true,

        # html and xhtml are supported by RDF::Format, so they can be used,
        # but they fail to return a proper RDF::Graph
        # "text/html"=> true,
        # "application/xhtml+xml"=> true,

        # content types that work
        content_types = {
          "application/ld+json"=> true,
          "application/rdf+xml"=> true,
          "text/turtle"=> true,
          "application/x-turtle"=> true,
        }
        # content types that fail
        content_types.merge!({
          "application/x-ld+json"=> false,
          "application/rdf+json"=> false,
          "text/rdf+turtle"=> false,
          "application/turtle"=> false,
          "application/n-triples"=> false,
          "application/rdf+n3"=> false,
          "text/n3"=> false,
          "text/rdf+n3"=> false,
          "text/plain"=> false,
          "application/n-quads"=> false,
          "text/x-nquads"=> false,
          "application/trig"=> false,
          "application/x-trig"=> false,
          "application/trix"=> false,
          "text/csv"=> false,
          "text/tab-separated-values"=>false,
          "application/csvm+json"=>false,
          })
        specs = content_types.map do |type,success|
          request_spec = <<EOS
it 'requests an open annotation by ID, with content type "#{type}"' do
  request_anno_with_content_type('#{type}')
end
EOS
          if success
            get_spec = <<EOS
it 'gets an open annotation by ID, with content type "#{type}"' do
  gets_anno_with_content_type('#{type}')
end
EOS
          else
            get_spec = <<EOS
it 'cannot get an open annotation by ID, with content type "#{type}"' do
  cannot_get_anno_with_content_type('#{type}')
end
EOS
          end
          request_spec + get_spec
        end
        eval(specs.join)
      end # using custom content type

    end # annotation by ID
  end # GET context

end

