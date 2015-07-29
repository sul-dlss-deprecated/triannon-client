require 'spec_helper'

# ::TriannonClient::TriannonClient class specs

describe 'TriannonClientDELETE', :vcr do

  before :all do
    # create a new annotation and call all the response processing utils.
    @anno = create_annotation('TriannonClientDELETE/create_annotation')
  end

  after :all do
    clear_annotations('TriannonClientDELETE/clear_annotations')
  end


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

