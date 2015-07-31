require 'spec_helper'

RSpec.shared_examples "create annotations" do |auth_required|
  let(:tc) {
    if auth_required
      triannon_config_auth
    else
      triannon_config_no_auth
    end
    TriannonClient::TriannonClient.new
  }
  it 'does not raise an error when submitting a valid open annotation' do
    expect(tc.authenticate).to eql(auth_required)
    response = nil
    expect do
      response = tc.post_annotation(jsonld_oa)
    end.not_to raise_error
    # Double check the POST by deleting the annotation.
    # If the POST was successful, the DELETE should work too.
    graph = tc.response2graph(response)
    uri = tc.annotation_uris(graph).first
    id = tc.annotation_id(uri)
    expect(tc.delete_annotation(id)).to be true
  end
  it 'returns a RestClient::Response object' do
    # The response behaves primarily as a String, so it can not be tested
    # as an instance of RestClient::Response, but it can be tested to respond
    # to RestClient::Response methods.
    expect(tc.authenticate).to eql(auth_required)
    anno = create_annotation
    r = anno[:response]
    expect(r.is_a? RestClient::Response).to be true
    expect(r).to respond_to(:code)
    expect(r).to respond_to(:body)
    expect(r).to respond_to(:headers)
  end
  it 'logs exceptions for RestClient::Exception' do
    expect(tc.authenticate).to eql(auth_required)
    response = double
    allow(response).to receive(:is_a?).and_return(RestClient::Response)
    allow(response).to receive(:headers).and_return(jsonld_content)
    allow(response).to receive(:body).and_return('post_logs_exceptions')
    allow(response).to receive(:code).and_return(500)
    exception = RestClient::Exception.new(response)
    data = {
      "commit"=>"Create Annotation",
      "annotation"=>{"data"=>"post_logs_exceptions"}
    }
    allow_any_instance_of(RestClient::Resource).to receive(:post).with(data).and_raise(exception)
    expect(TriannonClient.configuration.logger).to receive(:error).with(/post_logs_exceptions/)
    tc.post_annotation('post_logs_exceptions')
  end
  it 'logs exceptions' do
    expect(tc.authenticate).to eql(auth_required)
    exception = RuntimeError.new('post_logs_exceptions')
    data = {
      "commit"=>"Create Annotation",
      "annotation"=>{"data"=>"post_logs_exceptions"}
    }
    allow_any_instance_of(RestClient::Resource).to receive(:post).with(data).and_raise(exception)
    expect(TriannonClient.configuration.logger).to receive(:error).with(/post_logs_exceptions/)
    tc.post_annotation('post_logs_exceptions')
  end
end


describe 'TriannonClientCREATE', :vcr do

  after :all do
    clear_annotations('TriannonClientCREATE/clear_annotations')
  end

  describe "#post_annotation" do

    context 'without authentication' do
      auth_required = false # it's not required
      it_behaves_like 'create annotations', auth_required
    end

    context 'with authentication' do
      auth_required = true  # it must succeed
      it_behaves_like 'create annotations', auth_required
    end
  end

end
