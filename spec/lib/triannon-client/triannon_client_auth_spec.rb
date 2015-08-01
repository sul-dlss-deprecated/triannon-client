require 'spec_helper'

RSpec.shared_examples "authenticate" do |auth_required|

  let(:tc) {
    if auth_required
      triannon_config_auth
    else
      triannon_config_no_auth
    end
    TriannonClient::TriannonClient.new
  }

  def check_header
    headers = tc.site.headers
    expect(headers).to include(:Authorization)
    expect(headers[:Authorization]).to match(/Bearer/)
  end

  it "- #authenticate returns #{auth_required}" do
    if auth_required
      expect(tc.authenticate).to be_truthy
      check_header
    else
      expect(tc.authenticate).to be false
    end
  end

  it "- #authenticate! returns #{auth_required}" do
    # Authenticate and then test that authenticate!
    # will reset and renew the authentication.
    auth1 = tc.authenticate
    check_header if auth_required
    expect(tc.site.headers).to receive(:delete)
    if auth_required
      # renew the authentication
      expect(tc.authenticate!).to be_truthy
      check_header
      auth2 = tc.site.headers[:Authorization]
      expect(auth1).not_to eql(auth2)
    else
      expect(tc.authenticate!).to be false
    end
  end

end


describe 'TriannonClientAUTH', :vcr do

  context 'without authentication' do
    auth_required = false # it's not required
    it_behaves_like 'authenticate', auth_required
  end

  context 'with authentication' do
    auth_required = true  # it must succeed
    it_behaves_like 'authenticate', auth_required
  end

end
