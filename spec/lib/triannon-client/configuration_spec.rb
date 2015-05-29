require "spec_helper"

module TriannonClient

  describe Configuration do

    describe '#debug' do
      it 'default value is false' do
        ENV['DEBUG'] = nil
        config = Configuration.new
        expect(config.debug).to be_falsey
      end
    end

    describe '#debug=' do
      it 'can set value' do
        config = Configuration.new
        config.debug = true
        expect(config.debug).to be_truthy
      end
    end

    describe '#host' do
      it 'default value is http://localhost:3000' do
        ENV['TRIANNON_HOST'] = nil
        config = Configuration.new
        expect(config.host).to eql('http://localhost:3000')
      end
    end

    describe '#host=' do
      it 'can set value' do
        config = Configuration.new
        config.host = 'triannon.example.org'
        expect(config.host).to eql('triannon.example.org')
      end
    end

    describe '#container' do
      it 'default value is an empty string' do
        ENV['TRIANNON_CONTAINER'] = nil
        config = Configuration.new
        expect(config.container).to be_empty
      end
    end

    describe '#container=' do
      it 'can set value' do
        config = Configuration.new
        config.container = 'secret'
        expect(config.container).to eql('secret')
      end
    end

    describe '#user' do
      it 'default value is an empty string' do
        ENV['TRIANNON_USER'] = nil
        config = Configuration.new
        expect(config.user).to be_empty
      end
    end

    describe '#user=' do
      it 'can set value' do
        config = Configuration.new
        config.user = 'fred'
        expect(config.user).to eql('fred')
      end
    end

    describe '#pass' do
      it 'default value is an empty string' do
        ENV['TRIANNON_PASS'] = nil
        config = Configuration.new
        expect(config.pass).to be_empty
      end
    end

    describe '#pass=' do
      it 'can set value' do
        config = Configuration.new
        config.pass = 'secret'
        expect(config.pass).to eql('secret')
      end
    end

    describe '#oauth_client' do
      it 'default value is an empty string' do
        ENV['TRIANNON_OAUTH_ID'] = nil
        config = Configuration.new
        expect(config.oauth_client).to be_empty
      end
    end

    describe '#oauth_client=' do
      it 'can set value' do
        config = Configuration.new
        config.oauth_client = 'fred'
        expect(config.oauth_client).to eql('fred')
      end
    end

    describe '#oauth_secret' do
      it 'default value is an empty string' do
        ENV['TRIANNON_OAUTH_SECRET'] = nil
        config = Configuration.new
        expect(config.oauth_secret).to be_empty
      end
    end

    describe '#oauth_secret=' do
      it 'can set value' do
        config = Configuration.new
        config.oauth_secret = 'secret'
        expect(config.oauth_secret).to eql('secret')
      end
    end


  end
end
