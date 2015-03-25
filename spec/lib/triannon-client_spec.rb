require 'spec_helper'

# ::TriannonClient module specs

describe ::TriannonClient do

  describe ".configuration" do
    it "should be a configuration object" do
      expect(described_class.configuration).to be_a_kind_of ::TriannonClient::Configuration
    end
  end

  describe "#configure" do
    before :each do
      ::TriannonClient.configure do |config|
        config.debug = true
      end
    end
    it "returns a hash of options" do
      config = ::TriannonClient.configuration
      expect(config).to be_instance_of ::TriannonClient::Configuration
      expect(config.debug).to be_truthy
    end
    after :each do
      ::TriannonClient.reset
    end
  end

  describe ".reset" do
    before :each do
      ::TriannonClient.configure do |config|
        config.debug = true
      end
    end
    it "resets the configuration" do
      ::TriannonClient.reset
      config = ::TriannonClient.configuration
      expect(config).to be_instance_of ::TriannonClient::Configuration
      expect(config.debug).to be_falsey
    end
    after :each do
      ::TriannonClient.reset
    end
  end

end

