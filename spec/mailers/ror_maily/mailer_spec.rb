require 'spec_helper'

describe RoRmaily::Mailer do
  before(:each) do
    @entity = FactoryGirl.create :user
    @mailing = RoRmaily.dispatch(:ad_hoc_mail)
    @list = @mailing.list
  end

  context "without subscription" do
    it "should not deliver" do
      expect(RoRmaily::Log.delivered.count).to eq(0)

      AdHocMailer.ad_hoc_mail(@entity).deliver

      expect(RoRmaily::Log.delivered.count).to eq(0)
    end
  end

  context "with subscription" do
    before(:each) do
      @list.subscribe! @entity
    end

    it "should deliver" do
      expect(RoRmaily::Log.delivered.count).to eq(0)

      AdHocMailer.ad_hoc_mail(@entity).deliver

      expect(RoRmaily::Log.delivered.count).to eq(1)
    end
  end
end
