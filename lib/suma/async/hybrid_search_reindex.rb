# frozen_string_literal: true

require "amigo/job"

# When a member's membership is verified,
# make sure they are marked onboarding verified,
# so we don't have to update things in two places.
class Suma::Async::HybridSearchReindex
  extend Amigo::Job

  def perform(*arg)
    if arg.empty?
      reindexed = SequelHybridSearchable.reindex_all
      Suma::Async::JobLogger.set_job_tags(result: "reindexed_all_models", model_count: reindexed)
      return
    end
    cls = Kernel.const_get(arg[0])
    reindexed = cls.hybrid_search_reindex_all
    Suma::Async::JobLogger.set_job_tags(result: "reindexed_one_model", model_count: reindexed, model_name: arg[0])
  end
end
