require 'spec_helper'

describe RoRmaily::Mailer do
  before(:each) do
    @entity = FactoryGirl.create :user
    @mailing = RoRmaily.dispatch(:one_time_mail)
    @list = @mailing.list
  end

  describe "without subscription" do
    it "should not deliver" do
      RoRmaily::Log.delivered.count.should eq(0)

      CustomOneTimeMailer.one_time_mail(@entity).deliver

      RoRmaily::Log.delivered.count.should eq(0)
    end
  end

  describe "with subscription" do
    before(:each) do
      @list.subscribe! @entity
    end

    it "should deliver" do
      RoRmaily::Log.delivered.count.should eq(0)

      CustomOneTimeMailer.one_time_mail(@entity).deliver

      RoRmaily::Log.delivered.count.should eq(1)
    end
  end

  # missing mailers are how handled silently (bypassing Maily)
  #it "should handle missing mailer" do
    #expect { TestMailer.sample_mail_error(@entity).deliver }.to raise_error
  #end
end
