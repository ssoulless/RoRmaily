require 'spec_helper'

describe RoRmaily do
  describe "setup" do
    before(:each) do
      @user = FactoryGirl.create :user
    end

    it "should extend context entity models" do
      RoRmaily.context(:all_users).model.name.should eq(User.name)
      User.included_modules.should include(RoRmaily::ModelExtensions)

      @user.should respond_to(:maily_herald_subscriptions)

      @user.maily_herald_subscriptions.length.should be_zero
    end

    it "should create mailings from initializer" do
      mailing = RoRmaily.one_time_mailing(:test_mailing)
      mailing.should be_a RoRmaily::Mailing
      mailing.should_not be_a_new_record
    end

    it "should create sequences from initializer" do
      sequence = RoRmaily.sequence(:newsletters)
      sequence.should be_a RoRmaily::Sequence
      sequence.should_not be_a_new_record

      sequence.mailings.length.should eq(3)
    end
  end
end
