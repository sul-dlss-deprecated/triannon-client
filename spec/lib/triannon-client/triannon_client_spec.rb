require 'spec_helper'

# ::TriannonClient::TriannonClient class specs

describe TriannonClient, :vcr do

  before :all do
    Dotenv.load
    @oa_jsonld = '{"@context":"http://iiif.io/api/presentation/2/context.json","@graph":[{"@id":"_:g70349699654640","@type":["dctypes:Text","cnt:ContentAsText"],"chars":"I love this!","format":"text/plain","language":"en"},{"@type":"oa:Annotation","motivation":"oa:commenting","on":"http://purl.stanford.edu/kq131cs7229","resource":"_:g70349699654640"}]}'
  end

  let(:tc) { TriannonClient::TriannonClient.new }

  # Note: not using `let` approach for these methods because it
  # makes it very difficult to delete any annotations created by
  # the `tc.post_annotation`; so the `create_annotation` and the
  # `delete_annotation` methods are used in several before/after
  # blocks within describe blocks, as required.
  # let(:post_response)  { tc.post_annotation(@oa_jsonld) }
  # let(:anno_graph) { tc.response2graph(post_response) }
  # let(:anno_uri) { tc.annotation_uri(anno_graph) }
  # let(:anno_id) { tc.annotation_id(anno_uri) }

  def create_annotation
    r = tc.post_annotation(@oa_jsonld)
    g = tc.response2graph(r)
    uri = tc.annotation_uri(g)
    id = tc.annotation_id(uri)
    {
      response: r,
      graph: g,
      uri: uri,
      id: id
    }
  end

  def delete_annotation(id)
    tc.delete_annotation(id)
  end

  def graph_has_statements(graph)
    expect(graph).to be_instance_of RDF::Graph
    expect(graph).not_to be_empty
    expect(graph.size).to be > 2
  end

  def graph_is_empty(graph)
    expect(graph).to be_instance_of RDF::Graph
    expect(graph).to be_empty
  end

  def graph_contains_open_annotation(graph, uri)
    result = graph.query([nil, RDF.type, RDF::Vocab::OA.Annotation])
    expect(result.size).to be > 0
    expect(result.each_subject.collect{|s| s}).to include(uri)
  end

  describe 'has constants:' do
    it 'CONTENT_TYPES' do
      const = TriannonClient::TriannonClient::CONTENT_TYPES
      expect(const).to be_instance_of Array
      expect(const).to include('application/ld+json')
    end
    it 'PROFILE_TYPE_IIIF' do
      const = TriannonClient::TriannonClient::PROFILE_IIIF
      expect(const).to be_instance_of String
      expect(const).to include('http://iiif.io/api/presentation/2/context.json')
    end
    it 'PROFILE_TYPE_OA' do
      const = TriannonClient::TriannonClient::PROFILE_OA
      expect(const).to be_instance_of String
      expect(const).to include('http://www.w3.org/ns/oa-context-20130208.json')
    end
    it 'CONTENT_TYPE_IIIF' do
      const = TriannonClient::TriannonClient::CONTENT_TYPE_IIIF
      expect(const).to be_instance_of String
      expect(const).to include('application/ld+json')
      expect(const).to include('http://iiif.io/api/presentation/2/context.json')
    end
    it 'CONTENT_TYPE_OA' do
      const = TriannonClient::TriannonClient::CONTENT_TYPE_OA
      expect(const).to be_instance_of String
      expect(const).to include('application/ld+json')
      expect(const).to include('http://www.w3.org/ns/oa-context-20130208.json')
    end
    it 'JSONLD_TYPE' do
      const = TriannonClient::TriannonClient::JSONLD_TYPE
      expect(const).to be_instance_of String
      expect(const).to eql('application/ld+json')
    end
  end

  describe 'has public methods:' do
    it 'delete_annotation' do
      expect(tc).to respond_to(:delete_annotation)
    end
    it 'get_annotations' do
      expect(tc).to respond_to(:get_annotations)
    end
    it 'get_annotation' do
      expect(tc).to respond_to(:get_annotation)
    end
    it 'get_iiif_annotation' do
      expect(tc).to respond_to(:get_iiif_annotation)
    end
    it 'get_oa_annotation' do
      expect(tc).to respond_to(:get_oa_annotation)
    end
    it 'site' do
      expect(tc).to respond_to(:site)
    end
    # utilities
    it 'response2graph' do
      expect(tc).to respond_to(:response2graph)
    end
    it 'annotation_id' do
      expect(tc).to respond_to(:annotation_id)
    end
    it 'annotation_uri' do
      expect(tc).to respond_to(:annotation_uri)
    end
  end

  describe 'has private methods:' do
    it 'check_id' do
      expect(tc).not_to respond_to(:check_id)
    end
    it 'check_content_type' do
      expect(tc).not_to respond_to(:check_content_type)
    end
  end

  describe "#delete_annotation" do
    def test_delete_for_response_code(status, response)
      allow_any_instance_of(RestClient::Response).to receive(:code).and_return(status)
      expect(tc.delete_annotation('anything_here_is_OK')).to be response
    end
    it "returns false for a 500 response to a DELETE request" do
      test_delete_for_response_code(500, false)
    end
    it "returns true for a 200 response to a DELETE request" do
      test_delete_for_response_code(200, true)
    end
    it "returns true for a 202 response to a DELETE request" do
      test_delete_for_response_code(202, true)
    end
    it "returns true for a 204 response to a DELETE request" do
      test_delete_for_response_code(204, true)
    end
    it 'validates the annotation ID' do
      expect(tc).to receive(:check_id)
      tc.delete_annotation('anything_here_is_OK')
    end
    it 'deletes an open annotation that exists' do
      anno = create_annotation
      expect( tc.delete_annotation(anno[:id]) ).to be true
      graph = tc.get_annotation(anno[:id])
      graph_is_empty(graph)
    end
    it 'fails to delete an open annotation that does NOT exist' do
      id = 'anno_does_not_exist'
      graph = tc.get_annotation(id)
      graph_is_empty(graph)
      expect( tc.delete_annotation(id) ).to be false
    end
    it 'logs exceptions' do
      allow_any_instance_of(RestClient::Resource).to receive(:delete).and_raise('delete_exception')
      expect(TriannonClient.configuration.logger).to receive(:error).with(/delete_exception/)
      tc.delete_annotation('raise_delete_exception')
    end
    it 'quits after detecting an invalid annotation ID' do
      expect_any_instance_of(RestClient::Resource).not_to receive(:delete)
      tc.delete_annotation('') rescue nil
      tc.delete_annotation(nil) rescue nil
    end
    it 'uses RestClient::Resource.delete to DELETE a valid annotation ID' do
      expect_any_instance_of(RestClient::Resource).to receive(:delete)
      tc.delete_annotation(SecureRandom.uuid)
    end
  end

  describe "#get_annotations" do
    it 'returns an RDF::Graph' do
      graph = tc.get_annotations
      graph_has_statements(graph)
    end
    it 'returns an RDF::Graph that contains an AnnotationList' do
      graph = tc.get_annotations
      anno_list_uri = RDF::URI.parse('http://iiif.io/api/presentation/2#AnnotationList')
      result = graph.query([nil, nil, anno_list_uri])
      expect(result.size).to eql(1)
    end
    it 'returns an annotation list with an annotation created by a prior POST' do
      anno = create_annotation
      graph = tc.get_annotations
      graph_contains_open_annotation(graph, anno[:uri])
      delete_annotation(anno[:id])
    end
  end

  describe "GET annotation by ID:" do
    before(:example) do
      # create a new annotation and call all the response processing utils.
      @anno = create_annotation
    end
    after(:example) do
      delete_annotation(@anno[:id]) # cleanup after create_annotation
    end

    describe "#get_annotation" do
      context 'with content_type' do
        def request_anno_with_content_type(content_type)
          expect_any_instance_of(RestClient::Resource).to receive(:get).with(hash_including(:accept => content_type) )
          tc.get_annotation(@anno[:id], content_type)
        end
        def get_anno_with_content_type(content_type)
          graph = tc.get_annotation(@anno[:id], content_type)
          graph_has_statements(graph)
          graph_contains_open_annotation(graph, @anno[:uri])
        end
        it 'requests an open annotation by ID, with content type "application/ld+json"' do
          request_anno_with_content_type("application/ld+json")
        end
        it 'gets an open annotation by ID, with content type "application/ld+json"' do
          get_anno_with_content_type("application/ld+json")
        end
        # it 'requests an open annotation by ID, with content type "application/x-ld+json"' do
        #   request_anno_with_content_type("application/x-ld+json")
        # end
        # it 'gets an open annotation by ID, with content type "application/x-ld+json"' do
        #   get_anno_with_content_type("application/x-ld+json")
        # end
        # it 'requests an open annotation by ID, with content type "application/rdf+json"' do
        #   request_anno_with_content_type("application/rdf+json")
        # end
        # it 'gets an open annotation by ID, with content type "application/rdf+json"' do
        #   get_anno_with_content_type("application/rdf+json")
        # end
        it 'requests an open annotation by ID, with content type "text/turtle"' do
          request_anno_with_content_type("text/turtle")
        end
        it 'gets an open annotation by ID, with content type "text/turtle"' do
          get_anno_with_content_type("text/turtle")
        end
        # it 'requests an open annotation by ID, with content type "text/rdf+turtle"' do
        #   request_anno_with_content_type("text/rdf+turtle")
        # end
        # it 'gets an open annotation by ID, with content type "text/rdf+turtle"' do
        #   get_anno_with_content_type("text/rdf+turtle")
        # end
        # it 'requests an open annotation by ID, with content type "application/turtle"' do
        #   request_anno_with_content_type("application/turtle")
        # end
        # it 'gets an open annotation by ID, with content type "application/turtle"' do
        #   get_anno_with_content_type("application/turtle")
        # end
        it 'requests an open annotation by ID, with content type "application/x-turtle"' do
          request_anno_with_content_type("application/x-turtle")
        end
        it 'gets an open annotation by ID, with content type "application/x-turtle"' do
          get_anno_with_content_type("application/x-turtle")
        end
      end
      context 'without content_type' do
        it 'requests an open annotation by ID, accepting a default JSON-LD content' do
          graph_contains_open_annotation(@anno[:graph], @anno[:uri])
          content_type = TriannonClient::TriannonClient::JSONLD_TYPE
          expect_any_instance_of(RestClient::Resource).to receive(:get).with(hash_including(:accept => content_type) )
          tc.get_annotation(@anno[:id])
        end
        it 'checks the annotation ID' do
          expect(tc).to receive(:check_id)    # tested by #create_annotation
          graph_has_statements(@anno[:graph]) # check #create_annotation worked
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
        it 'returns an RDF graph with a valid ID for an annotation on the server' do
          graph = tc.get_annotation(@anno[:id])
          graph_has_statements(graph)
          graph_contains_open_annotation(@anno[:graph], @anno[:uri])
        end
        it 'returns an EMPTY RDF graph with a valid ID for NO annotation on the server' do
          id = SecureRandom.uuid
          graph = tc.get_annotation(id)
          graph_is_empty(graph)
        end
        it 'returns an EMPTY RDF graph for a 500 server response' do
          response = double
          allow(response).to receive(:is_a?).and_return(RestClient::Response)
          allow(response).to receive(:headers).and_return({content_type: 'application/ld+json'})
          allow(response).to receive(:code).and_return(500)
          allow_any_instance_of(RestClient::Resource).to receive(:get).and_return(response)
          graph = tc.get_annotation(@anno[:id])
          graph_is_empty(graph)
        end
        it 'logs exceptions' do
          allow_any_instance_of(RestClient::Resource).to receive(:get).and_raise('get_exception')
          expect(TriannonClient.configuration.logger).to receive(:error).with(/get_exception/)
          tc.get_annotation('raise_get_exception')
        end
      end
    end

    describe "#get_iiif_annotation" do
      # the mime type is fixed for this method
      it 'requests an open annotation by ID, using a IIIF profile' do
        graph_contains_open_annotation(@anno[:graph], @anno[:uri])
        content_type = TriannonClient::TriannonClient::CONTENT_TYPE_IIIF
        expect(tc).to receive(:get_annotation).with(@anno[:id], content_type)
        tc.get_iiif_annotation(@anno[:id])
      end
      it 'returns an RDF::Graph of an open annotation' do
        graph = tc.get_iiif_annotation(@anno[:id])
        graph_has_statements(graph)
        graph_contains_open_annotation(@anno[:graph], @anno[:uri])
      end
    end

    describe "#get_oa_annotation" do
      # the mime type is fixed for this method
      it 'requests an open annotation by ID, using an OA profile' do
        graph_contains_open_annotation(@anno[:graph], @anno[:uri])
        content_type = TriannonClient::TriannonClient::CONTENT_TYPE_OA
        expect(tc).to receive(:get_annotation).with(@anno[:id], content_type)
        tc.get_oa_annotation(@anno[:id])
      end
      it 'returns an RDF::Graph of an open annotation' do
        graph = tc.get_oa_annotation(@anno[:id])
        graph_has_statements(graph)
        graph_contains_open_annotation(@anno[:graph], @anno[:uri])
      end
    end

  end

  describe "#post_annotation" do
    it 'does not raise an error when submitting a valid open annotation' do
      response = nil
      expect do
        response = tc.post_annotation(@oa_jsonld)
      end.not_to raise_error
      # Double check the POST by deleting the annotation.
      # If the POST was successful, the DELETE should work too.
      graph = tc.response2graph(response)
      uri = tc.annotation_uri(graph)
      id = tc.annotation_id(uri)
      expect(tc.delete_annotation(id)).to be true
    end
    it 'returns a RestClient::Response object' do
      # The response behaves primarily as a String, so it can not be tested
      # as an instance of RestClient::Response, but it can be tested to respond
      # to RestClient::Response methods.
      anno = create_annotation
      r = anno[:response]
      expect(r.is_a? RestClient::Response).to be true
      expect(r).to respond_to(:code)
      expect(r).to respond_to(:body)
      expect(r).to respond_to(:headers)
      delete_annotation(anno[:id]) # cleanup after create_annotation
    end
  end


  describe 'response processing utilities' do

    before(:example) do
      # create a new annotation and call all the response processing utils.
      @anno = create_annotation
    end
    after(:example) do
      delete_annotation(@anno[:id]) # cleanup after create_annotation
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

    describe "#annotation_uri" do
      it "returns an RDF::URI from an RDF::Graph of an annotation" do
        expect(@anno[:graph]).to be_instance_of RDF::Graph
        expect(@anno[:uri]).to be_instance_of RDF::URI
      end
      it "returns an RDF::URI that is a valid URI" do
        expect(@anno[:uri]).to match(/\A#{URI::regexp}\z/)
        delete_annotation(@anno[:id]) # cleanup after create_annotation
      end
    end

    describe "#annotation_id" do
      it "returns a String ID from the RDF::URI of an annotation" do
        expect(@anno[:uri]).to be_instance_of RDF::URI
        expect(@anno[:id]).to be_instance_of String
      end
      it "returns a String ID that is not empty" do
        expect(@anno[:id]).to be_instance_of String
        expect(@anno[:id].empty?).to be false
      end
    end

  end

end

