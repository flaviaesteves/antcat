require 'spec_helper'

describe Feedback do
  describe "callbacks and validation" do
    it { should validate_presence_of(:comment) }

    describe "#add_emails_recipients" do
      it "has a default" do
        feedback = create :feedback
        expect(feedback.email_recipients).to eq "sblum@calacademy.org"
      end

      # TODO this should be mocked, but I'm not sure how to do that
      it "asks User" do
        create :editor, name: "Archibald",
          email: "archibald@antcat.org", receive_feedback_emails: true
        create :editor, name: "Batiatus",
          email: "batiatus@antcat.org", receive_feedback_emails: true

        create :editor, name: "Flint",
          email: "flint@antcat.org"

        feedback = create :feedback
        expect(feedback.email_recipients).to eq <<-STR.squish
          "Archibald" <archibald@antcat.org>,
          "Batiatus" <batiatus@antcat.org>
        STR
      end
    end
  end

  describe "scopes" do
    describe "scope.recently_created" do
      before do
        create :feedback
        create :feedback, created_at: (Time.now - 8.minutes)
        create :feedback, created_at: (Time.now - 3.days)
      end

      it "defaults to 5 minutes" do
        expect(Feedback.recently_created.count).to eq 1
      end

      it "accepts any value" do
        expect(Feedback.recently_created(10.minutes.ago).count).to eq 2
        expect(Feedback.recently_created(7.days.ago).count).to eq 3
      end
    end
  end

  describe "#from_the_same_ip" do
    before do
      create :feedback
      create :feedback, ip: "255.255.255.255"
    end

    it "finds feedbacks from" do
      feedback = create :feedback
      expect(feedback.from_the_same_ip.count).to eq 2
    end
  end

  describe "open/closed" do
    let(:open) { create :feedback }
    let(:closed) { create :feedback, open: false }

    describe "predicate methods" do
      describe "#open?" do
        it "knows" do
          expect(open.open?).to be true
          expect(closed.open?).to be false
        end
      end

      describe "#closed?" do
        it "knows" do
          expect(open.closed?).to be false
          expect(closed.closed?).to be true
        end
      end
    end

    describe "#close" do
      it "closes the feedback item" do
        open.close
        expect(open.closed?).to be true
      end
    end

    describe "#reopen" do
      it "reopens the feedback item" do
        closed.reopen
        expect(closed.closed?).to be false
      end
    end
  end
end
