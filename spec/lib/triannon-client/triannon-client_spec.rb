require 'spec_helper'

# ::TriannonClient::TriannonClient class specs

describe TriannonClient, :vcr do

  # Note: could use a 'let' pattern, but create_annotation can track data.
  # let(:post_response)  { @tc.post_annotation(@oa_jsonld) }
  # let(:response_graph) { @tc.response2graph(post_response) }
  # let(:annotation_uri) { @tc.annotation_uri(response_graph) }
  # let(:annotation_id)  { @tc.annotation_id(annotation_uri) }

  def create_annotation
    r = @tc.post_annotation(@oa_jsonld)
    g = @tc.response2graph(r)
    uri = @tc.annotation_uri(g)
    id = @tc.annotation_id(uri)
    {
      response: r,
      graph: g,
      uri: uri,
      id: id
    }
  end

  def check_graph_has_statements(graph)
    expect(graph).to be_instance_of RDF::Graph
    expect(graph.empty?).to be_falsy
    expect(graph.size > 2).to be_truthy
  end

  before :all do
    Dotenv.load
    @tc = TriannonClient::TriannonClient.new
    @oa_jsonld = '{"@context":"http://iiif.io/api/presentation/2/context.json","@graph":[{"@id":"_:g70349699654640","@type":["dctypes:Text","cnt:ContentAsText"],"chars":"I love this!","format":"text/plain","language":"en"},{"@type":"oa:Annotation","motivation":"oa:commenting","on":"http://purl.stanford.edu/kq131cs7229","resource":"_:g70349699654640"}]}'
  end

  before :each do
    @anno = create_annotation
  end

  after :each do
    @tc.delete_annotation(@anno[:id])
  end

  describe "#delete_annotation" do
    it "should handle a 204 response to DELETE request" do
      skip ("mock this properly")
      # back_end = double()
      # response = double
      # allow(response),to receive(:code).and_return(204)
      # allow(back_end).to receive(:delete).and_return(response)

      # allow_any_instance_of(RestClient).to receive(:delete)
      # allow(@tc).to receive(@sitle).and_return(back_end)
      # expect(@tc.delete_annotation).to be true
    end
    it 'should DELETE an open annotation that exists' do
      expect( @tc.delete_annotation(@anno[:id]) ).to be_truthy
    end
    it 'should fail to DELETE an open annotation that does NOT exist' do
      id = 'anno_does_not_exist'
      expect( @tc.delete_annotation(id) ).to be_falsy
    end
    it "logging" do
      skip ("mock this properly")
      # expect(@tc.send(:logger)).to receive(:error).with("could not delete id ")
      # # mock mock mock
      # @tc.delete_annotation(non-existen-id)  or return 404 or whatever
    end
    it "doesn't call the back end" do
      skip ("mock this properly")
      # allow(@tc).to receive(@rest_client).and_return(mock)
      # expect(@rest_client).not_to receive(:delete)
      # @tc.del
    end
  end

  describe "#get_annotations" do
    it 'should get an array of open annotations' do
      skip ("pending changes to triannon")
      # annos = @tc.get_annotations
      # expect(annos).to be_instance_of Array
      # expect(annos.length > 0).to be_truthy
    end
  end

  describe "#get_annotation" do
    context 'with content_type' do
      #TODO
    end
    context 'with no content_type' do
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
        expect(graph.empty?).to be_truthy
      end
    end
  end

  describe "#get_iiif_annotation" do
    # the mime type is fixed as 'ld+json' for this method
    it 'should get an open annotation by ID, using a IIIF profile' do
      graph = @tc.get_iiif_annotation(@anno[:id])
      check_graph_has_statements(graph)
      #TODO check that @tc client sends a request with the right profile header
    end
  end

  describe "#get_oa_annotation" do
    # the mime type is fixed as 'ld+json' for this method
    it 'should get an open annotation by ID, using an OA profile' do
      graph = @tc.get_oa_annotation(@anno[:id])
      check_graph_has_statements(graph)
      #TODO check that @tc client sends a request with the right profile header
    end
  end

  describe "#post_annotation" do
    it 'should POST an open annotation' do
      expect{@tc.post_annotation(@oa_jsonld)}.not_to raise_error
    end
    it 'returns a RestClient::Response object' do
      # The response behaves primarily as a String, so it can not be tested
      # as an instance of RestClient::Response, but it can be tested to respond
      # to RestClient methods, i.e.
      r = @anno[:response]
      expect(r.respond_to? 'code').to be_truthy
      expect(r.respond_to? 'body').to be_truthy
      expect(r.respond_to? 'headers').to be_truthy
    end
  end

  describe '#response2graph' do
    it 'turns RestClient::Response into RDF::Graph' do
      expect(@anno[:graph]).to be_instance_of RDF::Graph
    end
  end

  describe "#annotation_uri" do
    it "extracts an RDF::URI from an RDF::Graph of an annotation" do
      expect(@anno[:uri]).to be_instance_of RDF::URI
    end
    it "RDF::URI is a valid URI" do
      expect(@anno[:uri] =~ /\A#{URI::regexp}\z/).to be_truthy
    end
  end

  describe "#annotation_id" do
    it "extracts a String ID from the RDF::URI of an annotation" do
      expect(@anno[:id]).to be_instance_of String
    end
    it "extracts a String ID that is not empty" do
      expect(@anno[:id].empty?).to be_falsy
    end
  end




end

