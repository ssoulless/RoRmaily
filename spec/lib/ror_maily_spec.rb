require 'spec_helper'

describe RoRmaily do
  describe "setup" do
    before(:each) do
      @user = FactoryGirl.create :user
    end

    it "should extend context entity models" do
      RoRmaily.context(:all_users).model.name.should eq(User.name)
      User.included_modules.should include(RoRmaily::ModelExtensions)

      expect(@user).to respond_to(:ror_maily_subscriptions)
      expect(@user.ror_maily_subscriptions.length).to eq(0)
    end

    it "should create mailings from initializer" do
      mailing = RoRmaily.one_time_mailing(:test_mailing)
      expect(mailing).to be_kind_of(RoRmaily::Mailing)
      expect(mailing).not_to be_a_new_record
    end

    it "should create sequences from initializer" do
      sequence = RoRmaily.sequence(:newsletters)
      expect(sequence).to be_kind_of(RoRmaily::Sequence)
      expect(sequence).not_to be_a_new_record

      expect(sequence.mailings.length).to eq(3)
    end
  end
end
