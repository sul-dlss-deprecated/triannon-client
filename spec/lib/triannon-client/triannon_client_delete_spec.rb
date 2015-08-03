require 'spec_helper'

RSpec.shared_examples "delete annotations" do |auth_required|

  let(:tc) {
    if auth_required
      triannon_config_auth
    else
      triannon_config_no_auth
    end
    TriannonClient::TriannonClient.new
  }

  def test_delete_for_response_code(anno_id, status, result)
    response = double
    allow(response).to receive(:is_a?).and_return(RestClient::Response)
    allow(response).to receive(:headers).and_return(jsonld_content)
    allow(response).to receive(:body).and_return('delete_annotation')
    allow(response).to receive(:code).and_return(status)
    exception = RestClient::Exception.new(response)
    if [401, 404, 410, 500].include? status
      allow_any_instance_of(RestClient::Resource).to receive(:delete).and_raise(exception)
      if status == 401
        expect(tc).to receive(:authenticate).once # retry triggers auth
      else
        expect(tc).not_to receive(:authenticate)  # no retry
      end
    else
      allow_any_instance_of(RestClient::Resource).to receive(:delete).and_return(response)
      expect(tc).not_to receive(:authenticate)  # no retry
    end
    expect(tc.delete_annotation(anno_id)).to be result
  end
  it "DELETE 200 response returns true" do
    test_delete_for_response_code('200_is_true', 200, true)
  end
  it "DELETE 202 response returns true" do
    test_delete_for_response_code('202_is_true', 202, true)
  end
  it "DELETE 204 response returns true" do
    test_delete_for_response_code('204_is_true', 204, true)
  end
  it "DELETE 401 response initiates a retry with authentication" do
    test_delete_for_response_code('401_is_retry', 401, false)
  end
  it "DELETE 404 response returns true" do
    test_delete_for_response_code('404_is_true', 404, true)
  end
  it "DELETE 410 response returns true" do
    test_delete_for_response_code('410_is_true', 410, true)
  end
  it "DELETE 500 response returns false" do
    test_delete_for_response_code('500_is_false', 500, false)
  end
  it 'DELETE 404|410 does not log exceptions' do
    expect(tc.config.logger).not_to receive(:error)
    test_delete_for_response_code('404_is_true', 404, true)
    test_delete_for_response_code('410_is_true', 410, true)
  end
  it 'DELETE 500 logs exceptions' do
    expect(tc.config.logger).to receive(:error)
    test_delete_for_response_code('500_is_false', 500, false)
  end
  it 'validates the annotation ID' do
    expect(tc).to receive(:check_id)
    tc.delete_annotation('checking_anno_id')
  end
  it 'raises ArgumentError for an invalid annotation ID' do
    expect_any_instance_of(RestClient::Resource).not_to receive(:delete)
    expect { tc.delete_annotation('')  }.to raise_error(ArgumentError)
    expect { tc.delete_annotation(nil) }.to raise_error(ArgumentError)
  end
  it 'uses RestClient::Resource.delete to DELETE a valid annotation ID' do
    expect_any_instance_of(RestClient::Resource).to receive(:delete)
    tc.delete_annotation(SecureRandom.uuid)
  end
  it 'returns TRUE when deleting an annotation that exists' do
    anno = create_annotation
    expect( tc.delete_annotation(anno[:id]) ).to be true
    graph = tc.get_annotation(anno[:id])
    graph_is_empty(graph)
  end
  it 'returns TRUE when deleting an annotation that does NOT exist' do
    id = 'anno_does_not_exist'
    graph = tc.get_annotation(id)
    graph_is_empty(graph)
    expect( tc.delete_annotation(id) ).to be true
  end

end


describe 'TriannonClientDELETE', :vcr do

  # before :all do
  #   # create a new annotation and call all the response processing utils.
  #   @anno = create_annotation('TriannonClientDELETE/create_annotation')
  # end

  after :all do
    clear_annotations('TriannonClientDELETE/clear_annotations')
  end

  describe "#delete_annotation" do

    context 'without authentication' do
      auth_required = false # it's not required
      it_behaves_like 'delete annotations', auth_required
    end

    context 'with authentication' do
      auth_required = true  # it must succeed
      it_behaves_like 'delete annotations', auth_required
    end
  end

end
