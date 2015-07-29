require 'spec_helper'

# ::TriannonClient::TriannonClient class specs

describe 'TriannonClientCREATE', :vcr do

  before :all do
    # create a new annotation and call all the response processing utils.
    @anno = create_annotation('TriannonClientCREATE/create_annotation')
  end

  after :all do
    clear_annotations('TriannonClientCREATE/clear_annotations')
  end


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


end
