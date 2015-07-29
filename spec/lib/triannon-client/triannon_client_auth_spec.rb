require 'spec_helper'

# ::TriannonClient::TriannonClient class specs

describe 'TriannonClientAuth', :vcr do

  def create_client
    triannon_config_auth # spec_helper
    tc = TriannonClient::TriannonClient.new
    tc
  end

  before :all do
    @oa_jsonld = '{"@context":"http://iiif.io/api/presentation/2/context.json","@graph":[{"@id":"_:g70349699654640","@type":["dctypes:Text","cnt:ContentAsText"],"chars":"I love this!","format":"text/plain","language":"en"},{"@type":"oa:Annotation","motivation":"oa:commenting","on":"http://purl.stanford.edu/kq131cs7229","resource":"_:g70349699654640"}]}'
    # create a new annotation and call all the response processing utils.
    @anno = create_annotation
  end

  after :all do
    clear_annotations
  end

  def clear_annotations
    VCR.use_cassette('clear_annotations') do
      client = create_client
      client.authenticate
      annos = client.get_annotations
      q = [nil, RDF.type, RDF::Vocab::OA.Annotation]
      anno_ids = annos.query(q).subjects.collect {|s| client.annotation_id(s)}
      anno_ids.each {|id| client.delete_annotation(id) }
    end
  end

  def create_annotation
    VCR.use_cassette('create_annotation') do
      client = create_client
      client.authenticate
      r = client.post_annotation(@oa_jsonld)
      g = client.response2graph(r)
      uris = client.annotation_uris(g)
      id = client.annotation_id(uris.first)
      {
        response: r,
        graph: g,
        uris: uris,
        id: id
      }
    end
  end

  # def delete_annotation(id)
  #   client = create_client
  #   client.authenticate
  #   client.delete_annotation(id)
  # end

  context 'GET' do

    let(:tc) { TriannonClient::TriannonClient.new }

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
        allow(response).to receive(:body).and_return(@oa_jsonld)
        allow(response).to receive(:code).and_return(500)
        exception = RestClient::Exception.new(response)
        allow_any_instance_of(RestClient::Resource).to receive(:get).with(jsonld_accept).and_raise(exception)
        graph = tc.get_annotations
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
          allow(response).to receive(:body).and_return(@oa_jsonld)
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

    end # annotation by ID

  end # GET context

  #   describe "#get_annotation" do
  #     context 'with content_type' do
  #       # Content types could be supported for RDF::Format.content_types.keys,
  #       # but not all of them are supported.  The supported content types for
  #       # triannon are defined in
  #       # https://github.com/sul-dlss/triannon/blob/master/config/initializers/mime_types.rb
  #       # https://github.com/sul-dlss/triannon/blob/master/app/controllers/triannon/annotations_controller.rb
  #       # https://github.com/sul-dlss/triannon/blob/master/app/controllers/triannon/search_controller.rb
  #       # The default content type is "application/ld+json" and, at the time of
  #       # writing, triannon also supports:
  #       # turtle as:  ["application/x-turtle", "text/turtle"]
  #       # rdf+xml as: ["application/rdf+xml", "text/rdf+xml", "text/rdf"]
  #       # json as:    ["application/json", "text/x-json", "application/jsonrequest"]
  #       # xml as:     ["application/xml", "text/xml", "application/x-xml"]
  #       # html
  #       def request_anno_with_content_type(content_type)
  #         tc = create_client
  #         expect(tc.container).to receive(:get).with(hash_including(:accept => content_type) )
  #         tc.get_annotation(@anno[:id], content_type)
  #       end
  #       def gets_anno_with_content_type(content_type)
  #         tc = create_client
  #         graph = tc.get_annotation(@anno[:id], content_type)
  #         graph_contains_statements(graph)
  #         graph_contains_open_annotation(graph, @anno[:uri])
  #       end
  #       def cannot_get_anno_with_content_type(content_type)
  #         tc = create_client
  #         graph = tc.get_annotation(@anno[:id], content_type)
  #         graph_is_empty(graph)
  #       end
  #       #  "text/plain",
  #       #  "text/html",
  #       #  "application/xhtml+xml",
  #       it 'requests an open annotation by ID, with content type "application/ld+json"' do
  #         request_anno_with_content_type("application/ld+json")
  #       end
  #       it 'gets an open annotation by ID, with content type "application/ld+json"' do
  #         gets_anno_with_content_type("application/ld+json")
  #       end
  #       it 'requests an open annotation by ID, with content type "application/x-ld+json"' do
  #         request_anno_with_content_type("application/x-ld+json")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "application/x-ld+json"' do
  #         cannot_get_anno_with_content_type("application/x-ld+json")
  #       end
  #       it 'requests an open annotation by ID, with content type "application/rdf+json"' do
  #         request_anno_with_content_type("application/rdf+json")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "application/rdf+json"' do
  #         cannot_get_anno_with_content_type("application/rdf+json")
  #       end
  #       it 'requests an open annotation by ID, with content type "application/rdf+xml"' do
  #         request_anno_with_content_type("application/rdf+xml")
  #       end
  #       it 'gets an open annotation by ID, with content type "application/rdf+xml"' do
  #         gets_anno_with_content_type("application/rdf+xml")
  #       end
  #       it 'requests an open annotation by ID, with content type "text/turtle"' do
  #         request_anno_with_content_type("text/turtle")
  #       end
  #       it 'gets an open annotation by ID, with content type "text/turtle"' do
  #         gets_anno_with_content_type("text/turtle")
  #       end
  #       it 'requests an open annotation by ID, with content type "text/rdf+turtle"' do
  #         request_anno_with_content_type("text/rdf+turtle")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "text/rdf+turtle"' do
  #         cannot_get_anno_with_content_type("text/rdf+turtle")
  #       end
  #       it 'requests an open annotation by ID, with content type "application/turtle"' do
  #         request_anno_with_content_type("application/turtle")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "application/turtle"' do
  #         cannot_get_anno_with_content_type("application/turtle")
  #       end
  #       it 'requests an open annotation by ID, with content type "application/x-turtle"' do
  #         request_anno_with_content_type("application/x-turtle")
  #       end
  #       it 'gets an open annotation by ID, with content type "application/x-turtle"' do
  #         gets_anno_with_content_type("application/x-turtle")
  #       end
  #       it 'requests an open annotation by ID, with content type "application/n-triples"' do
  #         request_anno_with_content_type("application/n-triples")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "application/n-triples"' do
  #         cannot_get_anno_with_content_type("application/n-triples")
  #       end
  #       it 'requests an open annotation by ID, with content type "application/rdf+n3"' do
  #         request_anno_with_content_type("application/rdf+n3")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "application/rdf+n3"' do
  #         cannot_get_anno_with_content_type("application/rdf+n3")
  #       end
  #       it 'requests an open annotation by ID, with content type "text/n3"' do
  #         request_anno_with_content_type("text/n3")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "text/n3"' do
  #         cannot_get_anno_with_content_type("text/n3")
  #       end
  #       it 'requests an open annotation by ID, with content type "text/rdf+n3"' do
  #         request_anno_with_content_type("text/rdf+n3")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "text/rdf+n3"' do
  #         cannot_get_anno_with_content_type("text/rdf+n3")
  #       end
  #       it 'requests an open annotation by ID, with content type "application/n-quads"' do
  #         request_anno_with_content_type("application/n-quads")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "application/n-quads"' do
  #         cannot_get_anno_with_content_type("application/n-quads")
  #       end
  #       it 'requests an open annotation by ID, with content type "text/x-nquads"' do
  #         request_anno_with_content_type("text/x-nquads")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "text/x-nquads"' do
  #         cannot_get_anno_with_content_type("text/x-nquads")
  #       end
  #       it 'requests an open annotation by ID, with content type "application/trig"' do
  #         request_anno_with_content_type("application/trig")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "application/trig"' do
  #         cannot_get_anno_with_content_type("application/trig")
  #       end
  #       it 'requests an open annotation by ID, with content type "application/x-trig"' do
  #         request_anno_with_content_type("application/x-trig")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "application/x-trig"' do
  #         cannot_get_anno_with_content_type("application/x-trig")
  #       end
  #       it 'requests an open annotation by ID, with content type "application/trix"' do
  #         request_anno_with_content_type("application/trix")
  #       end
  #       it 'cannot get an open annotation by ID, with content type "application/trix"' do
  #         cannot_get_anno_with_content_type("application/trix")
  #       end
  #     end
  #   end
  # end




  # describe "#post_annotation" do
  #   before :each do
  #     # POST requires authentication
  #     tc.authenticate
  #   end
  #   it 'does not raise an error when submitting a valid open annotation' do
  #     response = nil
  #     expect do
  #       response = tc.post_annotation(@oa_jsonld)
  #     end.not_to raise_error
  #     # Double check the POST by deleting the annotation.
  #     # If the POST was successful, the DELETE should work too.
  #     graph = tc.response2graph(response)
  #     uri = tc.annotation_uris(graph).first
  #     id = tc.annotation_id(uri)
  #     expect(tc.delete_annotation(id)).to be true
  #   end
  #   it 'returns a RestClient::Response object' do
  #     # The response behaves primarily as a String, so it can not be tested
  #     # as an instance of RestClient::Response, but it can be tested to respond
  #     # to RestClient::Response methods.
  #     anno = create_annotation
  #     r = anno[:response]
  #     expect(r.is_a? RestClient::Response).to be true
  #     expect(r).to respond_to(:code)
  #     expect(r).to respond_to(:body)
  #     expect(r).to respond_to(:headers)
  #   end
  #   # it 'logs exceptions for RestClient::Exception' do
  #   #   exception_response = double()
  #   #   allow(exception_response).to receive(:code).and_return(500)
  #   #   allow(exception_response).to receive(:body).and_return('post_logs_exceptions')
  #   #   allow_any_instance_of(RestClient::Exception).to receive(:response).and_return(exception_response)
  #   #   expect(TriannonClient.configuration.logger).to receive(:error).with(/post_logs_exceptions/)
  #   #   tc.post_annotation('post_logs_exceptions')
  #   # end
  #   # it 'logs exceptions' do
  #   #   exception_response = double()
  #   #   allow(exception_response).to receive(:code).and_return(500)
  #   #   allow(exception_response).to receive(:body).and_return('post_logs_exceptions')
  #   #   allow_any_instance_of(RestClient::Exception).to receive(:response).and_return(exception_response)
  #   #   expect(TriannonClient.configuration.logger).to receive(:error).with(/post_logs_exceptions/)
  #   #   tc.post_annotation('post_logs_exceptions')
  #   # end
  # end




  # describe "#delete_annotation" do
  #   let(:tc) { create_client }
  #   # def test_delete_for_response_code(anno_id, status, response)
  #   #   allow_any_instance_of(RestClient::Response).to receive(:code).and_return(status)
  #   #   expect(tc.delete_annotation(anno_id)).to be response
  #   # end
  #   # it "returns FALSE for a 500 response to a DELETE request" do
  #   #   test_delete_for_response_code('500_is_false', 500, false)
  #   # end
  #   # it "returns TRUE for a 200 response to a DELETE request" do
  #   #   test_delete_for_response_code('200_is_true', 200, true)
  #   # end
  #   # it "returns TRUE for a 202 response to a DELETE request" do
  #   #   test_delete_for_response_code('202_is_true', 202, true)
  #   # end
  #   # it "returns TRUE for a 204 response to a DELETE request" do
  #   #   test_delete_for_response_code('204_is_true', 204, true)
  #   # end
  #   # it "returns TRUE for a 404 response to a DELETE request" do
  #   #   test_delete_for_response_code('404_is_true', 404, true)
  #   # end
  #   # it "returns TRUE for a 410 response to a DELETE request" do
  #   #   test_delete_for_response_code('410_is_true', 410, true)
  #   # end
  #   it 'validates the annotation ID' do
  #     expect(tc).to receive(:check_id)
  #     tc.delete_annotation('checking_anno_id')
  #   end
  #   # it 'quits after detecting an invalid annotation ID' do
  #   #   expect_any_instance_of(RestClient::Resource).not_to receive(:delete)
  #   #   tc.delete_annotation('') rescue nil
  #   #   tc.delete_annotation(nil) rescue nil
  #   # end
  #   # it 'uses RestClient::Resource.delete to DELETE a valid annotation ID' do
  #   #   expect_any_instance_of(RestClient::Resource).to receive(:delete)
  #   #   tc.delete_annotation(SecureRandom.uuid)
  #   # end
  #   it 'returns TRUE when deleting an open annotation that exists' do
  #     anno = create_annotation
  #     expect( tc.delete_annotation(anno[:id]) ).to be true
  #     graph = tc.get_annotation(anno[:id])
  #     graph_is_empty(graph)
  #   end
  #   it 'returns TRUE when deleting an open annotation that does NOT exist' do
  #     id = 'anno_does_not_exist'
  #     graph = tc.get_annotation(id)
  #     graph_is_empty(graph)
  #     expect( tc.delete_annotation(id) ).to be true
  #   end
  #   # it 'logs exceptions' do
  #   #   allow_any_instance_of(RestClient::Response).to receive(:code).and_return(450)
  #   #   allow_any_instance_of(RestClient::Response).to receive(:body).and_return('delete_logs_exceptions')
  #   #   expect(TriannonClient.configuration.logger).to receive(:error).with(/delete_logs_exceptions/)
  #   #   tc.delete_annotation('delete_logs_exceptions')
  #   # end
  #   # it 'does not log exceptions for missing annotations (404 responses)' do
  #   #   allow_any_instance_of(RestClient::Response).to receive(:code).and_return(404)
  #   #   allow_any_instance_of(RestClient::Response).to receive(:body).and_return('delete_does_not_log_404_exceptions')
  #   #   expect(TriannonClient.configuration.logger).not_to receive(:error)
  #   #   tc.delete_annotation('delete_does_not_log_404_exceptions')
  #   # end
  #   # it 'does not log exceptions for missing annotations (410 responses)' do
  #   #   allow_any_instance_of(RestClient::Response).to receive(:code).and_return(410)
  #   #   allow_any_instance_of(RestClient::Response).to receive(:body).and_return('delete_does_not_log_410_exceptions')
  #   #   expect(TriannonClient.configuration.logger).not_to receive(:error)
  #   #   tc.delete_annotation('delete_does_not_log_410_exceptions')
  #   # end
  # end

end

