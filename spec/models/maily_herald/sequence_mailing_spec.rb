require 'spec_helper'

describe RoRmaily::SequenceMailing do
  before(:each) do
    @sequence = RoRmaily.sequence(:newsletters)
    @mailing = @sequence.mailings.first
  end

  describe "Validations" do
    it do
      @mailing.absolute_delay = nil
      @mailing.should_not be_valid

      @mailing.absolute_delay = ""
      @mailing.should_not be_valid
    end
  end
end
