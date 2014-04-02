require 'spec_helper'

# Into this class instance we include subject module
class DummyReceiver
  include SUSE::Connect::Utilities
end

describe SUSE::Connect::Utilities do

  subject { DummyReceiver.new }

  describe '?token_auth' do

    it 'returns string for auth header' do
      subject.send(:token_auth, 'lambada').should eq 'Token token=lambada'
    end

    it 'raise if no token passed, but method requested' do
      expect { subject.send(:token_auth, nil) }
        .to raise_error CannotBuildTokenAuth, 'token auth requested, but no token provided'
    end

  end

  describe '?basic_auth' do

    it 'returns string for auth header' do
      System.stub(:credentials => %w{bob dylan})
      base64_line = 'Basic Ym9iOmR5bGFu'
      subject.send(:basic_auth).should eq base64_line
    end

    it 'raise if cannot get credentials' do
      System.stub(:credentials => nil)
      expect { subject.send(:basic_auth) }
      .to raise_error CannotBuildBasicAuth, 'cannot get proper username and password'
    end

  end

end
