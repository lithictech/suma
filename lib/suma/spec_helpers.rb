# frozen_string_literal: true

require "nokogiri"
require "rspec"
require "yajl"

require "suma"

RSpec::Matchers.define_negated_matcher(:exclude, :include)
RSpec::Matchers.define_negated_matcher(:not_include, :include)
RSpec::Matchers.define_negated_matcher(:not_change, :change)
RSpec::Matchers.define_negated_matcher(:not_be_nil, :be_nil)
RSpec::Matchers.define_negated_matcher(:not_be_empty, :be_empty)
RSpec::Matchers.define_negated_matcher(:not_be_a, :be_a)

module Suma::SpecHelpers
  # The directory to look in for fixture data
  TEST_DATA_DIR = Pathname("spec/data").expand_path

  def self.included(context)
    context.before(:all) do
      Suma::Member.password_hash_cost = 1
    end
    super
  end

  ### Load data from the spec/data directory with the specified +name+,
  ### deserializing it if it's YAML or JSON, and returning it.
  module_function def load_fixture_data(name, raw: false)
    name = name.to_s
    path = TEST_DATA_DIR + name
    path = TEST_DATA_DIR + "#{name}.json" unless path.exist? || !File.extname(name).empty?
    path = TEST_DATA_DIR + "#{name}.yaml" unless path.exist? || !File.extname(name).empty?
    path = TEST_DATA_DIR + "#{name}.yml" unless path.exist? || !File.extname(name).empty?
    path = TEST_DATA_DIR + "#{name}.xml" unless path.exist? || !File.extname(name).empty?

    rawdata = path.read(encoding: "utf-8")

    return rawdata if raw

    return case path.extname
      when ".json"
        Yajl::Parser.parse(rawdata)
      when ".yml", ".yaml"
        YAML.safe_load(rawdata)
      when ".xml"
        Nokogiri::XML(rawdata)
      else
        rawdata
    end
  end

  module_function def fixture_response(path=nil, body: nil, status: 200, format: :json, headers: {})
    raise ArgumentError, "need path or body" if path.nil? && body.nil?
    respbody = body || load_fixture_data(path, raw: true)
    case format
      when :json
        headers["Content-Type"] = "application/json"
      when :xml
        headers["Content-Type"] = "application/xml"
    end
    return {status:, body: respbody, headers:}
  end

  module_function def json_response(body={}, status: 200, headers: {})
    headers["Content-Type"] = "application/json"
    body = body.to_json
    return {status:, body:, headers:}
  end

  module_function def money(x, *more)
    return x if x.is_a?(Money)
    return Monetize.parse!(x) if x.is_a?(String)
    return Money.new(x, *more)
  end
end
