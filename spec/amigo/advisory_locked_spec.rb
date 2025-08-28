# frozen_string_literal: true

require "amigo/advisory_locked"

RSpec.describe Amigo::AdvisoryLocked do
  def connectdb(&) = Sequel.connect(ENV.fetch("DATABASE_URL"), &)

  before(:all) do
    @oldmode = Sidekiq::Testing.__test_mode
    Sidekiq::Testing.disable!
    @db = connectdb
  end

  after(:all) do
    Sidekiq::Testing.__set_test_mode(@oldmode)
    @db.disconnect
  end

  before(:each) do
    Sidekiq.redis(&:flushdb)
    Sidekiq.default_configuration.server_middleware.add(described_class::ServerMiddleware)
  end

  after(:each) do
    Sidekiq.default_configuration.server_middleware.remove(described_class::ServerMiddleware)
    Sidekiq.redis(&:flushdb)
  end

  let(:db) { @db }

  define_method(:job_cls) do |cb: nil, db: @db, **opts|
    cls = Class.new do
      include Sidekiq::Job

      def self.to_s = "Amigo::AdvisoryLocked::TestClass"
      def self.runs = @runs ||= []

      sidekiq_options(advisory_lock: {db:}.merge(**opts))

      attr_accessor :runs

      define_method :perform do |*args|
        self.class.runs ||= []
        self.class.runs << args
        cb&.call
      end
    end
    stub_const(cls.to_s, cls)
    cls
  end

  it "runs the job" do
    cls = job_cls
    cls.perform_async
    cls.perform_async(1)
    drain_sidekiq_jobs(Sidekiq::Queue.new)
    expect(cls.runs).to eq([[1], []])
  end

  it "schedules for the future if the lock is taken and backoff is not set" do
    cls = job_cls
    expect(cls).to receive(:perform_in).with(60)
    cls.perform_async
    connectdb do |db|
      described_class.advisory_lock(cls, db:).with_lock do
        drain_sidekiq_jobs(Sidekiq::Queue.new)
      end
    end
    expect(cls.runs).to eq([])
  end

  it "does not reschedule if the lock is taken and backoff is nil" do
    cls = job_cls(backoff: nil)
    expect(cls).to_not receive(:perform_in)
    cls.perform_async
    connectdb do |db|
      described_class.advisory_lock(cls, db:).with_lock do
        drain_sidekiq_jobs(Sidekiq::Queue.new)
      end
    end
    expect(cls.runs).to eq([])
  end

  it "uses the given backoff if not set" do
    cls = job_cls(backoff: 5)
    expect(cls).to receive(:perform_in).with(5)
    cls.perform_async
    connectdb do |db|
      described_class.advisory_lock(cls, db:).with_lock do
        drain_sidekiq_jobs(Sidekiq::Queue.new)
      end
    end
    expect(cls.runs).to eq([])
  end

  it "will invoke a callable to get the database" do
    cls = job_cls(db: -> { raise ClosedQueueError })
    cls.perform_async
    expect { drain_sidekiq_jobs(Sidekiq::Queue.new) }.to raise_error(ClosedQueueError)
  end

  it "hashes the class name as the key" do
    low, high = Sequel::AdvisoryLock.key_to_parts(Amigo::AdvisoryLocked.string_to_int64(job_cls.to_s))
    cls = job_cls(
      cb: -> { expect(@db[:pg_locks].where(objid: low, classid: high).all).to have_attributes(length: 1) },
    )
    cls.perform_async
    drain_sidekiq_jobs(Sidekiq::Queue.new)
    expect(cls.runs).to eq([[]])
  end

  it "will use the given key rather than the hashed class name" do
    cls = job_cls(
      key: 123_789,
      cb: -> { expect(@db[:pg_locks].where(objid: 123_789, classid: 0).all).to have_attributes(length: 1) },
    )
    cls.perform_async
    drain_sidekiq_jobs(Sidekiq::Queue.new)
    expect(cls.runs).to eq([[]])
  end
end
