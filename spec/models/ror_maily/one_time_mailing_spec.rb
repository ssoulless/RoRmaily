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
        @mailing.should be_a RoRmaily::OneTimeMailing
        @mailing.should_not be_a_new_record
        @mailing.should be_valid
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

<<<<<<< HEAD
        expect(RoRmaily::Subscription.count).to eq(1)
        expect(RoRmaily::Log.delivered.count).to eq(0)
=======
        expect(MailyHerald::Subscription.count).to eq(1)
        expect(MailyHerald::Log.delivered.count).to eq(0)
        expect(@mailing.logs.scheduled.count).to eq(1)
>>>>>>> 1aa39a0... Introducing AdHocMailer

        subscription.should be_kind_of(RoRmaily::Subscription)

        @mailing.conditions_met?(@entity).should be_truthy
        @mailing.processable?(@entity).should be_truthy
        @mailing.mailer_name.should eq(:generic)

        ret = @mailing.run
        ret.should be_a(Array)
        ret.first.should be_a(MailyHerald::Log)
        ret.first.should be_delivered
        ret.first.mail.should be_a(Mail::Message)

        RoRmaily::Subscription.count.should eq(1)
        RoRmaily::Log.delivered.count.should eq(1)

        log = RoRmaily::Log.delivered.first
        log.entity.should eq(@entity)
        log.mailing.should eq(@mailing)
        log.entity_email.should eq(@entity.email)
      end
    end

    describe "single entity delivery" do
<<<<<<< HEAD
      before(:each) do
        @mailing = RoRmaily.one_time_mailing(:test_mailing)
        @mailing.should be_a RoRmaily::OneTimeMailing
        @mailing.should_not be_a_new_record
      end

      it "should be delivered" do
        RoRmaily::Log.delivered.count.should eq(0)
        msg = TestMailer.sample_mail(@entity).deliver
        msg.should be_a(Mail::Message)
        RoRmaily::Log.delivered.count.should eq(1)
      end

      it "should not be delivered if subscription inactive" do
        @list.unsubscribe!(@entity)
        RoRmaily::Log.delivered.count.should eq(0)
        TestMailer.sample_mail(@entity).deliver
        RoRmaily::Log.delivered.count.should eq(0)
=======
      it "should not be possible via Mailer" do
        MailyHerald::Log.delivered.count.should eq(0)

        schedule = MailyHerald.dispatch(:one_time_mail).schedule_for(@entity)
        schedule.update_attribute(:processing_at, Time.now + 1.day)

        msg = CustomOneTimeMailer.one_time_mail(@entity).deliver

        MailyHerald::Log.delivered.count.should eq(0)
>>>>>>> 1aa39a0... Introducing AdHocMailer
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
<<<<<<< HEAD
      @mailing = RoRmaily.one_time_mailing(:sample_mail)
=======
      @mailing = MailyHerald.one_time_mailing(:one_time_mail)
>>>>>>> 1aa39a0... Introducing AdHocMailer
      @mailing.update_attribute(:override_subscription, true)
    end

    after(:each) do
      @mailing.update_attribute(:override_subscription, false)
    end

<<<<<<< HEAD
    it "single mail should be delivered" do
      RoRmaily::Log.delivered.count.should eq(0)
=======
    it "should deliver single mail" do
      MailyHerald::Log.delivered.count.should eq(0)
>>>>>>> 1aa39a0... Introducing AdHocMailer
      @mailing.processable?(@entity).should be_truthy
      @mailing.override_subscription?.should be_truthy
      @mailing.enabled?.should be_truthy
      msg = CustomOneTimeMailer.one_time_mail(@entity).deliver
      msg.should be_a(Mail::Message)
      RoRmaily::Log.delivered.count.should eq(1)
    end
  end

end
