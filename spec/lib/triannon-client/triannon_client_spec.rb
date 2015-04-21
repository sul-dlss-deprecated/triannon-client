require 'spec_helper'

# ::TriannonClient::TriannonClient class specs

describe TriannonClient, :vcr do

  # Note: could use a 'let' pattern, but create_annotation can track data.
  # let(:post_response)  { @tc.post_annotation(@oa_jsonld) }
  # let(:response_graph) { @tc.response2graph(post_response) }
  # let(:annotation_uri) { @tc.annotation_uri(response_graph) }
  # let(:annotation_id)  { @tc.annotation_id(annotation_uri) }

  def create_annotation
    tc = TriannonClient::TriannonClient.new
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
    tc = TriannonClient::TriannonClient.new
    tc.delete_annotation(id)
  end

  def check_graph_has_statements(graph)
    expect(graph).to be_instance_of RDF::Graph
    expect(graph).not_to be_empty
    expect(graph.size).to be > 2
  end

  before :all do
    Dotenv.load
    @oa_jsonld = '{"@context":"http://iiif.io/api/presentation/2/context.json","@graph":[{"@id":"_:g70349699654640","@type":["dctypes:Text","cnt:ContentAsText"],"chars":"I love this!","format":"text/plain","language":"en"},{"@type":"oa:Annotation","motivation":"oa:commenting","on":"http://purl.stanford.edu/kq131cs7229","resource":"_:g70349699654640"}]}'
  end

  describe 'has constant' do
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

  describe 'responds to' do
    before(:example) do
      @tc = TriannonClient::TriannonClient.new
    end
    it 'delete_annotation' do
      expect(@tc).to respond_to(:delete_annotation)
    end
    it 'get_annotations' do
      expect(@tc).to respond_to(:get_annotations)
    end
    it 'get_annotation' do
      expect(@tc).to respond_to(:get_annotation)
    end
    it 'get_iiif_annotation' do
      expect(@tc).to respond_to(:get_iiif_annotation)
    end
    it 'get_oa_annotation' do
      expect(@tc).to respond_to(:get_oa_annotation)
    end
    it 'site' do
      expect(@tc).to respond_to(:site)
    end
    # utilities
    it 'response2graph' do
      expect(@tc).to respond_to(:response2graph)
    end
    it 'annotation_id' do
      expect(@tc).to respond_to(:annotation_id)
    end
    it 'annotation_uri' do
      expect(@tc).to respond_to(:annotation_uri)
    end
  end

  describe 'has private method' do
    before(:example) do
      @tc = TriannonClient::TriannonClient.new
    end
    it 'check_id' do
      expect(@tc).not_to respond_to(:check_id)
    end
    it 'check_content_type' do
      expect(@tc).not_to respond_to(:check_content_type)
    end
  end

  describe "#delete_annotation" do
    before(:example) do
      @tc = TriannonClient::TriannonClient.new
    end
    def test_delete_for_response_code(status, response)
      allow_any_instance_of(RestClient::Response).to receive(:code).and_return(status)
      expect(@tc.delete_annotation('anything_here_is_OK')).to be response
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
    it 'checks the annotation ID' do
      allow(@tc).to receive(:check_id)
      @tc.delete_annotation('anything_here_is_OK')
      expect(@tc).to have_received(:check_id)
    end
    it 'deletes an open annotation that exists' do
      anno = create_annotation
      expect( @tc.delete_annotation(anno[:id]) ).to be true
    end
    it 'fails to delete an open annotation that does NOT exist' do
      id = 'anno_does_not_exist'
      expect( @tc.delete_annotation(id) ).to be false
    end
    it 'logs exceptions' do
      allow_any_instance_of(RestClient::Response).to receive(:code).and_raise('trigger_logging')
      expect(TriannonClient.configuration.logger).to receive(:error).with(/trigger_logging/)
      @tc.delete_annotation('anything_here_is_OK')
    end
    it 'does NOT set a path to DELETE an invalid annotation ID' do
      expect(@tc.site).not_to receive(:[])
      @tc.delete_annotation('') rescue nil
      @tc.delete_annotation(nil) rescue nil
    end
    it 'sets a path to DELETE a valid annotation ID' do
      expect(@tc.site).to receive(:[])
      @tc.delete_annotation('a_non_empty_string_is_OK')
    end
  end

  describe "#get_annotations" do
    before(:example) do
      @tc = TriannonClient::TriannonClient.new
    end
    it 'returns an RDF::Graph' do
      annos = @tc.get_annotations
      expect(annos).to be_instance_of RDF::Graph
    end
    it 'returns an RDF::Graph that contains an AnnotationList' do
      annos = @tc.get_annotations
      anno_list_uri = RDF::URI.parse('http://iiif.io/api/presentation/2#AnnotationList')
      result = annos.query([nil, nil, anno_list_uri])
      expect(result.size).to eql(1)
    end
    it 'returns an annotation list with an annotation created by a prior POST' do
      anno = create_annotation
      annos = @tc.get_annotations
      result = annos.query([nil, RDF.type, RDF::Vocab::OA.Annotation])
      expect(result.size).to eql(1)
      expect(result.each_subject.collect{|s| s}).to include(anno[:uri])
      @tc.delete_annotation(anno[:id])
    end
  end


  describe "get_methods" do
    before(:example) do
      # create a new annotation and call all the response processing utils.
      @tc = TriannonClient::TriannonClient.new
      @anno = create_annotation
    end
    after(:example) do
      delete_annotation(@anno[:id]) # cleanup after create_annotation
    end

    describe "#get_annotation" do
      context 'with content_type' do
        #TODO
      end
      context 'with no content_type' do
        it 'checks the annotation ID' do
          allow(@tc).to receive(:check_id)
          @tc.get_annotation('anything_here_is_OK') rescue nil
          expect(@tc).to have_received(:check_id)
        end
        it 'raises an argument error with a nil ID' do
          expect{@tc.get_annotation(nil)}.to raise_error(ArgumentError)
        end
        it 'raises an argument error with an integer ID' do
          expect{@tc.get_annotation(0)}.to raise_error(ArgumentError)
        end
        it 'raises an argument error with an empty string ID' do
          expect{@tc.get_annotation('')}.to raise_error(ArgumentError)
        end
        it 'returns an RDF graph with a valid ID for an annotation on the server' do
          graph = @tc.get_annotation(@anno[:id])
          check_graph_has_statements(graph)
        end
        it 'returns an EMPTY RDF graph with a valid ID for NO annotation on the server' do
          id = SecureRandom.uuid
          graph = @tc.get_annotation(id)
          expect(graph).to be_instance_of RDF::Graph
          expect(graph.empty?).to be true
        end
      end
    end

    describe "#get_iiif_annotation" do
      # the mime type is fixed as 'ld+json' for this method
      it 'requests an open annotation by ID, using a IIIF profile' do
        graph = @tc.get_iiif_annotation(@anno[:id])
        check_graph_has_statements(graph)
        #TODO check that client sends a request with the right profile header
      end
    end

    describe "#get_oa_annotation" do
      # the mime type is fixed as 'ld+json' for this method
      it 'requests an open annotation by ID, using an OA profile' do
        graph = @tc.get_iiif_annotation(@anno[:id])
        check_graph_has_statements(graph)
        #TODO check that client sends a request with the right profile header
      end
    end

  end

  describe "#post_annotation" do
    it 'does not raise an error when submitting a valid open annotation' do
      tc = TriannonClient::TriannonClient.new
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
      # TODO: stub and mock this OR test the response is an Open Anno?
    end
    it 'returns a RestClient::Response object' do
      # The response behaves primarily as a String, so it can not be tested
      # as an instance of RestClient::Response, but it can be tested to respond
      # to RestClient methods.
      anno = create_annotation
      r = anno[:response]
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

