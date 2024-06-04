# frozen_string_literal: true

require "rack"

class Rack::Csp
  def initialize(app, policy: "default-src 'self'", header: "Content-Security-Policy")
    @app = app
    policy = Policy.from_hash(policy) if policy.is_a?(Hash)
    @policy = policy.to_s
    @header = header
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers[@header] = @policy
    [status, headers, body]
  end

  def self.extract_script_hashes(html, xpath: "//script[@data-csp='ok']")
    doc = Nokogiri::HTML5.parse(html)
    elements = doc.xpath(xpath)
    return elements.map { |s| Digest::SHA256.base64digest(s) }
  end

  class Policy
    attr_reader :safe, :inline_scripts, :script_hashes, :img_data, :parts

    def self.from_hash(h)
      explicit_parts = h[:parts]
      params = {}
      parts = {}
      h.each do |k, v|
        if k.is_a?(String)
          parts[k] = v
        else
          params[k] = v
        end
      end
      parts.merge!(explicit_parts) if explicit_parts
      params[:parts] = parts
      return self.new(**params)
    end

    def initialize(
      safe: "'self'",
      inline_scripts: [],
      script_hashes: [],
      img_data: false,
      parts: {}
    )
      safe = safe.compact.join(" ") if safe.respond_to?(:to_ary)
      @safe = safe
      @inline_scripts = inline_scripts
      @script_hashes = script_hashes
      @img_data = img_data
      @parts = parts
    end

    SAFE = "<SAFE>"

    def to_s
      all_script_hashes = script_hashes
      all_script_hashes += inline_scripts.map { |s| Digest::SHA256.base64digest(s) }

      img_src = +safe.dup
      img_src << " data:" if img_data

      script_src = +safe.dup
      all_script_hashes.each do |h|
        script_src << " 'sha256-"
        script_src << h
        script_src << "'"
      end

      all_parts = {
        "default-src" => safe,
        "img-src" => img_src,
        "script-src" => script_src,
      }
      parts.each do |k, v|
        v = v.gsub(SAFE, safe)
        all_parts[k] = v
      end
      return all_parts.map { |k, v| "#{k} #{v}" }.join("; ")
    end
  end
end
