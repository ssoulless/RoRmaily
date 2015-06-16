require 'spec_helper'

describe RoRmaily::Log do
  before(:each) do
    @mailing = RoRmaily.periodical_mailing(:weekly_summary)
    @entity = FactoryGirl.create :user
  end

  describe "Associations" do
    it "should have proper scopes" do
      log = RoRmaily::Log.create_for @mailing, @entity, {status: :delivered}
      expect(log).to be_valid
      expect(log.entity).to eq(@entity)
      expect(log.mailing).to eq(@mailing)

      expect(RoRmaily::Log.for_entity(@entity)).to include(log)
      expect(RoRmaily::Log.for_mailing(@mailing)).to include(log)

      expect(RoRmaily::Log.for_entity(@entity).for_mailing(@mailing).last).to eq(log)
    end
  end

  it "should have proper scopes" do
    log1 = RoRmaily::Log.create_for @mailing, @entity, {status: :delivered}
    log2 = RoRmaily::Log.create_for @mailing, @entity, {status: :delivered}
    expect(RoRmaily::Log.count).to eq(2)

    log1.update_attribute(:status, :skipped)
    expect(RoRmaily::Log.count).to eq(2)
    expect(RoRmaily::Log.skipped.count).to eq(1)

    log1.update_attribute(:status, :error)
    expect(RoRmaily::Log.count).to eq(2)
    expect(RoRmaily::Log.error.count).to eq(1)
  end
end
