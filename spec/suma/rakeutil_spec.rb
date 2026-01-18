# frozen_string_literal: true

require "suma/rakeutil"

RSpec.describe Suma::Rakeutil do
  describe "readall_nonblock" do
    it "reads the full io" do
      s = +""
      num_digits = 1024 * rand(6..12) * (1 + rand)
      (1..num_digits).each { |i| s << "#{i}_" }
      Tempfile.create do |tf|
        tf << s
        tf.flush
        tf.rewind
        got = described_class.readall_nonblock(tf)
        expect(got).to eq(s)
      end
    end

    it "returns empty string if the io is empty" do
      Tempfile.create do |tf|
        got = described_class.readall_nonblock(tf)
        expect(got).to eq("")
      end
    end

    it "retries reads when WaitReadable is raised due to nobblocking IO" do
      # To test this for real, do something like:
      # ( sleep 5; echo "hello" ) | bundle exec rake mobility:sync:limereport
      io = fake_nonblocking_io.new(
        "a",
        "b",
        :wait,
        "c",
        :wait,
        :wait,
        :wait,
        "d",
        "e",
      )
      got = described_class.readall_nonblock(io, 8)
      expect(got).to eq("aaaaaaaabbbbbbbbccccccccddddddddeeeeeeee")
    end

    let(:fake_nonblocking_io) do
      Class.new do
        def initialize(*commands)
          @commands = commands.dup
        end

        def to_io
          return Class.new do
            def initialize(io)
              @io = io
            end

            # rubocop:disable Naming/PredicateMethod
            def wait_readable(_size) = true
            # rubocop:enable Naming/PredicateMethod
            def read_nonblock(size, chunk) = @io.read_nonblock(size, chunk)
          end.new(self)
        end

        def read_nonblock(size, chunk)
          cmd = @commands.shift
          case cmd
            when :wait
              raise IO::EAGAINWaitReadable
            when nil
              raise EOFError
            else
              return chunk[..size] = cmd * size
          end
        end
      end
    end
  end
end
