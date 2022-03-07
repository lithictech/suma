# frozen_string_literal: true

require "faker"

module Faker::Suma
  class << self
    def s3_url(region: nil, bucket: nil, key: nil)
      region ||= "us-#{['east', 'west', 'central'].sample}-#{['1', '2'].sample}"
      bucket ||= Faker::Lorem.word
      key ||= "#{Faker::Lorem.word}/#{Faker::Lorem.word}.#{['png', 'jpg', 'jpeg'].sample}"
      return "http://#{bucket}.s3.#{region}.amazonaws.com/#{key}"
    end

    def image_url(opts={})
      opts[:protocol] ||= ["https", "http"].sample
      opts[:host] ||= ["facebook.com", "flickr.com", "mysite.com"].sample
      opts[:path] ||= "fld"
      opts[:filename] ||= Faker::Lorem.word
      opts[:ext] ||= ["png", "jpg", "jpeg"].sample
      return "#{opts[:protocol]}://#{opts[:host]}/#{opts[:path]}/#{opts[:filename]}.#{opts[:ext]}"
    end

    def us_phone
      s = +"1"
      # First char is never 0 in US area codes
      s << Faker::Number.between(from: 1, to: 9).to_s
      Array.new(9) do
        s << Faker::Number.between(from: 0, to: 9).to_s
      end
      return s
    end
  end
end
