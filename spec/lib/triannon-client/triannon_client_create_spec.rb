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

  def check_authentication(required)
    auth = tc.authenticate
    if required
      expect(auth).to be_truthy
    else
      expect(auth).to be false
    end
  end

  let(:exception_data) { 'post_exception' }
  let(:exception_post) {
    {
      "commit"=>"Create Annotation",
      "annotation"=>{"data"=>exception_data}
    }
  }
  let(:exception_msg)  { 'create_exception' }

  def raise_restclient_exception(status)
    response = double
    allow(response).to receive(:is_a?).and_return(RestClient::Response)
    allow(response).to receive(:headers).and_return(jsonld_content)
    allow(response).to receive(:body).and_return(exception_msg)
    allow(response).to receive(:code).and_return(status)
    exception = RestClient::Exception.new(response)
    allow_any_instance_of(RestClient::Resource).to receive(:post).with(exception_post).and_raise(exception)
    if status == 401
      expect(tc).to receive(:authenticate).once # retry triggers authentication
    else
      expect(tc).not_to receive(:authenticate)  # no retry
    end
  end

  it 'does not raise an error when submitting a valid open annotation' do
    check_authentication(auth_required)
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
    check_authentication(auth_required)
    anno = create_annotation
    r = anno[:response]
    expect(r.is_a? RestClient::Response).to be true
    expect(r).to respond_to(:code)
    expect(r).to respond_to(:body)
    expect(r).to respond_to(:headers)
  end
  it 'POST 401 response retries and logs RestClient::Exception message' do
    check_authentication(auth_required)
    raise_restclient_exception(401)
    expect(TriannonClient.configuration.logger).to receive(:error).with(/#{exception_msg}/)
    tc.post_annotation(exception_data)
  end
  it 'POST 403 response does not retry and logs RestClient::Exception message' do
    check_authentication(auth_required)
    raise_restclient_exception(403)
    expect(TriannonClient.configuration.logger).to receive(:error).with(/#{exception_msg}/)
    tc.post_annotation(exception_data)
  end
  it 'POST 500 response does not retry and logs RestClient::Exception message' do
    check_authentication(auth_required)
    raise_restclient_exception(500)
    expect(TriannonClient.configuration.logger).to receive(:error).with(/#{exception_msg}/)
    tc.post_annotation(exception_data)
  end
  it 'logs RuntimeError message' do
    check_authentication(auth_required)
    exception = RuntimeError.new(exception_msg)
    allow_any_instance_of(RestClient::Resource).to receive(:post).with(exception_post).and_raise(exception)
    expect(TriannonClient.configuration.logger).to receive(:error).with(/#{exception_msg}/)
    tc.post_annotation(exception_data)
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
