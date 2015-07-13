require 'spec_helper'

describe RoRmaily::AdHocMailing do
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
        @mailing = RoRmaily.ad_hoc_mailing(:ad_hoc_mail)
        expect(@mailing).to be_kind_of(RoRmaily::AdHocMailing)
        expect(@mailing).not_to be_a_new_record
      end

      it "should not be delivered without explicit scheduling" do
        expect(RoRmaily::Subscription.count).to eq(1)
        expect(@mailing.conditions_met?(@entity)).to be_truthy
        expect(@mailing.processable?(@entity)).to be_truthy

        expect(@mailing.logs.scheduled.count).to eq(0)
        expect(@mailing.logs.processed.count).to eq(0)

        @mailing.run

        expect(@mailing.logs.scheduled.count).to eq(0)
        expect(@mailing.logs.processed.count).to eq(0)
      end

      it "should be delivered" do
        subscription = @mailing.subscription_for(@entity)

        expect(RoRmaily::Subscription.count).to eq(1)
        expect(RoRmaily::Log.delivered.count).to eq(0)

        expect(subscription).to be_kind_of(RoRmaily::Subscription)

        expect(@mailing.conditions_met?(@entity)).to be_truthy
        expect(@mailing.processable?(@entity)).to be_truthy

        @mailing.schedule_delivery_to_all Time.now - 5

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
      before(:each) do
        @mailing = RoRmaily.ad_hoc_mailing(:ad_hoc_mail)
        expect(@mailing).to be_kind_of(RoRmaily::AdHocMailing)
        expect(@mailing).not_to be_a_new_record
      end

      context "without explicit scheduling" do
        it "should be delivered using Mailer deliver method" do
          RoRmaily::Log.delivered.count.should eq(0)
          msg = AdHocMailer.ad_hoc_mail(@entity).deliver
          msg.should be_a(Mail::Message)
          RoRmaily::Log.delivered.count.should eq(1)
          expect(RoRmaily::Log.delivered.first.entity).to eq(@entity)
        end
      end

      context "with explicit scheduling" do
        it "should be delivered" do
          RoRmaily::Log.delivered.count.should eq(0)

          @mailing.schedule_delivery_to @entity, Time.now - 5

          msg = AdHocMailer.ad_hoc_mail(@entity).deliver

          msg.should be_a(Mail::Message)
          RoRmaily::Log.delivered.count.should eq(1)
        end

        it "should not be delivered if subscription inactive" do
          @mailing.schedule_delivery_to @entity, Time.now - 5

          @list.unsubscribe!(@entity)

          RoRmaily::Log.delivered.count.should eq(0)

          AdHocMailer.ad_hoc_mail(@entity).deliver

          RoRmaily::Log.delivered.count.should eq(0)
        end
      end
    end

    describe "with entity outside the scope" do
      before(:each) do
        @mailing = RoRmaily.ad_hoc_mailing(:ad_hoc_mail)
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
      @mailing = RoRmaily.ad_hoc_mailing(:ad_hoc_mail)
      @mailing.update_attribute(:override_subscription, true)
    end

    after(:each) do
      @mailing.update_attribute(:override_subscription, false)
    end

    it "single mail should be delivered" do
      RoRmaily::Log.delivered.count.should eq(0)
      @mailing.processable?(@entity).should be_truthy
      @mailing.override_subscription?.should be_truthy
      @mailing.enabled?.should be_truthy

      @mailing.schedule_delivery_to @entity, Time.now - 5

      msg = AdHocMailer.ad_hoc_mail(@entity).deliver
      msg.should be_a(Mail::Message)

      RoRmaily::Log.delivered.count.should eq(1)
    end
  end

end
