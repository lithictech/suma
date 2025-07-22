# frozen_string_literal: true

require "suma/spec_helpers/rake"
require "suma/tasks/frontend"

RSpec.describe Suma::Tasks::Frontend, :db, :redirect do
  include Suma::SpecHelpers::Rake

  describe "frontend:build_webapp" do
    it "builds the app" do
      expect(Kernel).to receive(:`).with("bin/build-webapp") do
        Kernel.system("exit 0")
      end
      expect(Kernel).to_not receive(:exit)

      invoke_rake_task("frontend:build_webapp")
      expect($stdout.string).to eq("")
      expect($stderr.string).to eq("")
    end

    it "exits if build exits nonzero" do
      expect(Kernel).to receive(:`).with("bin/build-webapp") do
        Kernel.system("exit 99")
      end
      expect(Kernel).to receive(:exit).with(99)
      invoke_rake_task("frontend:build_webapp")
      expect($stdout.string).to eq("Non-zero exit status: 99\n")
      expect($stderr.string).to eq("")
    end
  end

  describe "frontend:build_adminapp" do
    it "builds the app" do
      expect(Kernel).to receive(:`).with("bin/build-adminapp") do
        Kernel.system("exit 0")
      end
      expect(Kernel).to_not receive(:exit)

      invoke_rake_task("frontend:build_adminapp")
      expect($stdout.string).to eq("")
      expect($stderr.string).to eq("")
    end
  end
end
