# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Finance < Rake::TaskLib
  def initialize
    super()
    namespace :finance do
      task :run_financial_model do
        require "suma"
        Suma.load_app
        require "suma/payment/financial_modeling/model_202309"
        c = Suma::Payment::FinancialModeling::Model202309.new.build_model(1.month.ago)
        File.write("temp/suma-financial-model.csv", c)
      end
    end
  end
end
