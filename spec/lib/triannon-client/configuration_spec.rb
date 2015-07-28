require "spec_helper"

module TriannonClient

  describe Configuration do

    before :each do
      config_keys = ENV.keys.select {|k| k =~ /TRIANNON/ }
      config_keys.each {|k| ENV.delete k }
      ::TriannonClient.reset
    end

    let(:config) { Configuration.new }

    describe '#debug' do
      it 'default value is false' do
        expect(config.debug).to be_falsey
      end
    end

    describe '#debug=' do
      it 'can set value' do
        config.debug = true
        expect(config.debug).to be_truthy
      end
    end

    describe '#host' do
      it 'default value is http://localhost:3000' do
        expect(config.host).to eql('http://localhost:3000')
      end
    end

    describe '#host=' do
      it 'can set value' do
        config.host = 'triannon.example.org'
        expect(config.host).to eql('triannon.example.org')
      end
    end

    # triannon doesn't support basic auth, so disabled these config params.
    # describe '#user' do
    #   it 'default value is an empty string' do
    #     expect(config.user).to be_empty
    #   end
    # end
    # describe '#user=' do
    #   it 'can set value' do
    #     config.user = 'fred'
    #     expect(config.user).to eql('fred')
    #   end
    # end
    # describe '#pass' do
    #   it 'default value is an empty string' do
    #     expect(config.pass).to be_empty
    #   end
    # end
    # describe '#pass=' do
    #   it 'can set value' do
    #     config.pass = 'secret'
    #     expect(config.pass).to eql('secret')
    #   end
    # end

    describe '#client_id' do
      it 'default value is an empty string' do
        expect(config.client_id).to be_empty
      end
    end

    describe '#client_id=' do
      it 'can set value' do
        config.client_id = 'fred'
        expect(config.client_id).to eql('fred')
      end
    end

    describe '#client_pass' do
      it 'default value is an empty string' do
        expect(config.client_pass).to be_empty
      end
    end

    describe '#client_pass=' do
      it 'can set value' do
        config.client_pass = 'secret'
        expect(config.client_pass).to eql('secret')
      end
    end

    describe '#container' do
      it 'default value is an empty string' do
        expect(config.container).to be_empty
      end
    end

    describe '#container=' do
      it 'can set value' do
        config.container = 'foo'
        expect(config.container).to eql('foo')
      end
    end

    describe '#container_user' do
      it 'default value is an empty string' do
        expect(config.container_user).to be_empty
      end
    end

    describe '#container_user=' do
      it 'can set value' do
        config.container_user = 'joe'
        expect(config.container_user).to eql('joe')
      end
    end

    describe '#container_workgroups' do
      it 'default value is an empty string' do
        expect(config.container_workgroups).to be_empty
      end
    end

    describe '#container_workgroups=' do
      it 'can set value' do
        config.container_workgroups = 'wgA'
        expect(config.container_workgroups).to eql('wgA')
      end
    end

    describe '#logger' do
      it 'default value is a Logger' do
        expect(config.logger).to be_instance_of(Logger)
      end
    end

  end
end
