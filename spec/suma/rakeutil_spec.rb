# frozen_string_literal: true

require "rake/tasklib"

require "suma/rakeutil"
require "suma/spec_helpers/rake"

RSpec.describe Suma::Rakeutil do
  include Suma::SpecHelpers::Rake

  describe "readall" do
    it "reads the full io" do
      s = +""
      num_digits = 1024 * rand(6..12) * (1 + rand)
      (1..num_digits).each do |i|
        s << "#{i}_"
        s << "\n" if (i % 10).zero?
      end
      Tempfile.create do |tf|
        tf << s
        tf.flush
        tf.rewind
        got = described_class.readall(tf)
        expect(got).to eq(s)
      end
    end

    it "returns empty string if the io is empty" do
      Tempfile.create do |tf|
        got = described_class.readall(tf)
        expect(got).to eq("")
      end
    end
  end

  describe "readfile" do
    it "reads the file using ARGF (final arg is filename)" do
      buffer = StringIO.new
      task = create_rake_task { |_task, params| buffer.write(Suma::Rakeutil.readfile(params)) }
      txt = "hello\nworld\n"
      Tempfile.create do |tf|
        tf << txt
        tf.flush
        tf.rewind
        invoke_rake_task(task.name, tail: [tf.path])
      end
      expect(buffer.string).to eq(txt)
    end

    it "reads the file using a filename task parameter" do
      buffer = StringIO.new
      task = create_rake_task(args: [:filename]) { |_task, params| buffer.write(Suma::Rakeutil.readfile(params)) }
      txt = "hello\nworld\n"
      Tempfile.create do |tf|
        tf << txt
        tf.flush
        tf.rewind
        invoke_rake_task(task.name, tf.path)
      end
      expect(buffer.string).to eq(txt)
    end

    it "reads from stdin" do
      buffer = StringIO.new
      task = create_rake_task(args: [:filename]) { |_task, params| buffer.write(Suma::Rakeutil.readfile(params)) }
      txt = "hello\nworld\n"
      expect($stdin).to receive(:tty?).and_return(false)
      expect($stdin).to receive(:each_line) do |&block|
        txt.lines.each(&block)
      end
      invoke_rake_task(task.name)
      expect(buffer.string).to eq(txt)
    end

    it "reads the contents of a redis key" do
      buffer = StringIO.new
      txt = "hello\nworld\n"
      Sidekiq.redis do |c|
        c.set("xyz", txt)
      end
      task = create_rake_task { |_task, params| buffer.write(Suma::Rakeutil.readfile(params)) }
      invoke_rake_task(task.name, tail: ["redis://xyz"])
      expect(buffer.string).to eq(txt)
    end

    it "reads the contents of a url" do
      txt = "hello\nworld\n"
      req = stub_request(:get, "https://xyz/").
        to_return(body: txt)
      buffer = StringIO.new
      task = create_rake_task { |_task, params| buffer.write(Suma::Rakeutil.readfile(params)) }
      invoke_rake_task(task.name, tail: ["https://xyz"])
      expect(buffer.string).to eq(txt)
      expect(req).to have_been_made
    end

    it "returns nil if no argument is provided" do
      got = []
      task = create_rake_task { |_task, params| got << Suma::Rakeutil.readfile(params) }
      invoke_rake_task(task.name)
      expect(got).to eq([nil])
    end
  end
end
