# frozen_string_literal: true

module Suma::Async::JobUtils
  def self.included(cls)
    cls.include(InstanceMethods)
  end

  module InstanceMethods
    def with_log_tags(tags, &)
      Suma::Async::JobLogger.with_log_tags(tags, &)
    end

    def set_job_tags(tags)
      Suma::Async::JobLogger.set_job_tags(**tags)
    end
  end
end
