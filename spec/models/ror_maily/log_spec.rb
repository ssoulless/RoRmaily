require 'spec_helper'

describe RoRmaily::Log do
  before(:each) do
    @mailing = RoRmaily.periodical_mailing(:weekly_summary)
    @entity = FactoryGirl.create :user
  end

  describe "Associations" do
    it "should have proper scopes" do
      log = RoRmaily::Log.create_for @mailing, @entity, {status: :delivered}
      log.should be_valid
      log.entity.should eq(@entity)
      log.mailing.should eq(@mailing)

      RoRmaily::Log.for_entity(@entity).should include(log)
      RoRmaily::Log.for_mailing(@mailing).should include(log)

      RoRmaily::Log.for_entity(@entity).for_mailing(@mailing).last.should eq(log)
    end
  end

  it "should have proper scopes" do
    log1 = RoRmaily::Log.create_for @mailing, @entity, {status: :delivered}
    log2 = RoRmaily::Log.create_for @mailing, @entity, {status: :delivered}
    expect(RoRmaily::Log.count).to eq(2)

    log1.update_attribute(:status, :skipped)
    RoRmaily::Log.count.should eq(2)
    RoRmaily::Log.skipped.count.should eq(1)

    log1.update_attribute(:status, :error)
    RoRmaily::Log.count.should eq(2)
    RoRmaily::Log.error.count.should eq(1)
  end
end
