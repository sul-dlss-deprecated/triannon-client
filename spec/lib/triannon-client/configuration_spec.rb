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

    describe '#client_id' do
      it 'default value is an empty string' do
        ENV['TRIANNON_CLIENT_ID'] = nil
        config = Configuration.new
        expect(config.client_id).to be_empty
      end
    end

    describe '#client_id=' do
      it 'can set value' do
        config = Configuration.new
        config.client_id = 'fred'
        expect(config.client_id).to eql('fred')
      end
    end

    describe '#client_pass' do
      it 'default value is an empty string' do
        ENV['TRIANNON_CLIENT_ID'] = nil
        config = Configuration.new
        expect(config.client_pass).to be_empty
      end
    end

    describe '#client_pass=' do
      it 'can set value' do
        config = Configuration.new
        config.client_pass = 'secret'
        expect(config.client_pass).to eql('secret')
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
        config.container = 'foo'
        expect(config.container).to eql('foo')
      end
    end

    describe '#container_user' do
      it 'default value is an empty string' do
        ENV['TRIANNON_CONTAINER_USER'] = nil
        config = Configuration.new
        expect(config.container_user).to be_empty
      end
    end

    describe '#container_user=' do
      it 'can set value' do
        config = Configuration.new
        config.container_user = 'joe'
        expect(config.container_user).to eql('joe')
      end
    end

    describe '#container_workgroups' do
      it 'default value is an empty string' do
        ENV['TRIANNON_CONTAINER_WORKGROUPS'] = nil
        config = Configuration.new
        expect(config.container_workgroups).to be_empty
      end
    end

    describe '#container_workgroups=' do
      it 'can set value' do
        config = Configuration.new
        config.container_workgroups = 'wgA'
        expect(config.container_workgroups).to eql('wgA')
      end
    end

  end
end
