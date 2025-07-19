# frozen_string_literal: true

require "suma/spec_helpers/rake"
require "suma/messages/order_confirmation"
require "suma/tasks/message"

RSpec.describe Suma::Tasks::Message, :db do
  include Suma::SpecHelpers::Rake

  describe "render" do
    before(:each) do
      stub_const("Suma::RACK_ENV", "development")
      @stdout = named_stdout
      @stderr = named_stderr
      @orig_stdout = $stdout
      @orig_stderr = $stderr
      $stdout = @stdout
      $stderr = @stderr
    end

    after(:each) do
      $stdout = @orig_stdout
      $stderr = @orig_stderr
    end

    it "renders html to stdout and feedback and other bodies to stderr" do
      invoke_rake_task("message:render", "Testers::Basic")
      expect(@stdout.string).to include("<p>email to")
      expect(@stderr.string).to include("Created #<Suma::Message::Delivery")
      expect(@stderr.string).to include("Writing text/html to <STDOUT>")
      expect(@stderr.string).to include("\nsubject to ")
      expect(@stderr.string).to include("\nemail to ")
    end

    it "writes html to output path" do
      tf = Tempfile.create
      invoke_rake_task("message:render", "Testers::Basic", tf.path)
      expect(@stderr.string).to include("Created #<Suma::Message::Delivery")
      expect(@stderr.string).to include("Writing text/html to #{tf.path}")
      expect(@stderr.string).to include("\nemail to ")
      expect(@stdout.string).to be_empty
      expect(File.read(tf.path)).to include("<p>email to")
    end

    it "works for dynamic templates" do
      invoke_rake_task("message:render", "OrderConfirmation", "-", "es", "sms")
      expect(@stdout.string).to include("test confirmation (es)")
      expect(@stderr.string).to include("Created #<Suma::Message::Delivery")
    end

    it "works for other transports (and outputs single-body to output, not feedback, stream)" do
      invoke_rake_task("message:render", "Testers::Basic", "-", "en", "sms")
      expect(@stdout.string).to include("sms to")
      expect(@stderr.string).to include("Created #<Suma::Message::Delivery")
    end
  end
end
