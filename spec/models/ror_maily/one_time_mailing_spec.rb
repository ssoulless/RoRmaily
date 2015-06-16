require 'spec_helper'

describe RoRmaily::OneTimeMailing do
  before(:each) do
    @entity = FactoryGirl.create :user

    @list = RoRmaily.list(:generic_list)
    expect(@list.context).to be_a(RoRmaily::Context)
  end

  describe "with subscription" do
    before(:each) do
      @list.subscribe!(@entity)
    end

    describe "run all delivery" do
      before(:each) do
        @mailing = RoRmaily.one_time_mailing(:test_mailing)
        expect(@mailing).to be_kind_of(RoRmaily::OneTimeMailing)
        expect(@mailing).not_to be_a_new_record
        expect(@mailing).to be_valid
      end

      it "should be delivered only once per user" do
        subscription = @mailing.subscription_for(@entity)

        expect(@mailing.logs.scheduled.count).to eq(1)
        expect(@mailing.schedules.for_entity(@entity).count).to eq(1)

        ret = @mailing.run

        expect(@mailing.logs.processed.for_entity(@entity).count).to eq(1)
        expect(@mailing.schedules.for_entity(@entity).count).to eq(0)

        @mailing.set_schedules

        expect(@mailing.schedules.for_entity(@entity).count).to eq(0)

        ret = @mailing.run

        expect(@mailing.logs.processed.for_entity(@entity).count).to eq(1)
        expect(@mailing.schedules.for_entity(@entity).count).to eq(0)
      end

      it "should be delivered" do
        subscription = @mailing.subscription_for(@entity)

        expect(RoRmaily::Subscription.count).to eq(1)
        expect(RoRmaily::Log.delivered.count).to eq(0)
        expect(@mailing.logs.scheduled.count).to eq(1)

        expect(subscription).to be_kind_of(RoRmaily::Subscription)

        expect(@mailing.conditions_met?(@entity)).to be_truthy
        expect(@mailing.processable?(@entity)).to be_truthy
        expect(@mailing.mailer_name).to eq(:generic)

        ret = @mailing.run
        expect(ret).to be_kind_of(Array)
        expect(ret.first).to be_kind_of(RoRmaily::Log)
        expect(ret.first).to be_delivered
        expect(ret.first.mail).to be_kind_of(Mail::Message)

        expect(RoRmaily::Subscription.count).to eq(1)
        expect(RoRmaily::Log.delivered.count).to eq(1)

        log = RoRmaily::Log.delivered.first
        expect(log.entity).to eq(@entity)
        expect(log.mailing).to eq(@mailing)
        expect(log.entity_email).to eq(@entity.email)
      end
    end

    describe "single entity delivery" do
      it "should not be possible via Mailer" do
        expect(RoRmaily::Log.delivered.count).to eq(0)

        schedule = RoRmaily.dispatch(:one_time_mail).schedule_for(@entity)
        schedule.update_attribute(:processing_at, Time.now + 1.day)

        msg = CustomOneTimeMailer.one_time_mail(@entity).deliver

        expect(RoRmaily::Log.delivered.count).to eq(0)
      end
    end

    describe "with entity outside the scope" do
      before(:each) do
        @mailing = RoRmaily.one_time_mailing(:test_mailing)
      end

      it "should not process mailings" do
        expect(@list.context.scope).to include(@entity)
        expect(@mailing).to be_processable(@entity)
        expect(@mailing).to be_enabled

        @entity.update_attribute(:active, false)

        expect(@list.context.scope).not_to include(@entity)
        expect(@list).to be_subscribed(@entity)

        expect(@mailing).not_to be_processable(@entity)
      end
    end
  end

  describe "with subscription override" do
    before(:each) do
      @mailing = RoRmaily.one_time_mailing(:one_time_mail)
      @mailing.update_attribute(:override_subscription, true)
    end

    after(:each) do
      @mailing.update_attribute(:override_subscription, false)
    end

    it "should deliver single mail" do
      expect(RoRmaily::Log.delivered.count).to eq(0)
      expect(@mailing.processable?(@entity)).to be_truthy
      expect(@mailing.override_subscription?).to be_truthy
      expect(@mailing.enabled?).to be_truthy
      msg = CustomOneTimeMailer.one_time_mail(@entity).deliver
      expect(msg).to be_kind_of(Mail::Message)
      expect(RoRmaily::Log.delivered.count).to eq(1)
    end
  end

end
