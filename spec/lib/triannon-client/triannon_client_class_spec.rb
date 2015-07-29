require 'spec_helper'

# ::TriannonClient::TriannonClient class specs

describe 'TriannonClientClass' do

  let(:tc) {
    triannon_config_no_auth # spec_helper
    TriannonClient::TriannonClient.new
  }

  describe 'has constants:' do
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

  describe 'public attributes:' do
    # attribute accessors
    it 'config' do
      expect(tc).to respond_to(:config)
    end
    it 'site' do
      expect(tc).to respond_to(:site)
    end
    it 'auth' do
      expect(tc).to respond_to(:auth)
    end
    it 'container' do
      expect(tc).to respond_to(:container)
    end
  end

  describe 'public methods:' do
    # methods
    it 'authenticate' do
      expect(tc).to respond_to(:authenticate)
    end
    it 'delete_annotation' do
      expect(tc).to respond_to(:delete_annotation)
    end
    it 'get_annotations' do
      expect(tc).to respond_to(:get_annotations)
    end
    it 'get_annotation' do
      expect(tc).to respond_to(:get_annotation)
    end
    it 'get_iiif_annotation' do
      expect(tc).to respond_to(:get_iiif_annotation)
    end
    it 'get_oa_annotation' do
      expect(tc).to respond_to(:get_oa_annotation)
    end
    # utilities
    it 'response2graph' do
      expect(tc).to respond_to(:response2graph)
    end
    it 'annotation_id' do
      expect(tc).to respond_to(:annotation_id)
    end
    it 'annotation_uris' do
      expect(tc).to respond_to(:annotation_uris)
    end
  end

  describe 'private:' do
    it 'check_id' do
      expect(tc).not_to respond_to(:check_id)
    end
    it 'check_content_type' do
      expect(tc).not_to respond_to(:check_content_type)
    end
  end

end
