# frozen_string_literal: true

require "image_processing"
require "vips"

module Suma::ImageProcessor
  class InvalidOption < StandardError
    def initialize(field, value)
      super("invalid #{field}: #{value}")
    end
  end

  FORMAT_VALUES = [:png, :jpeg].freeze
  # See https://github.com/janko/image_processing/blob/master/doc/vips.md#resize_to_limit
  RESIZE_VALUES = [:limit, :fill].freeze
  # See https://www.libvips.org/API/current/libvips-conversion.html#VipsInteresting
  CROP_VALUES = [:center, :none, :entropy, :attention, :low, :high].freeze

  # @return [Vips::Image]
  def self.from_file(f)
    return Vips::Image.new_from_file(f.path)
  end

  # @return [Vips::Image]
  def self.from_buffer(b)
    return Vips::Image.new_from_buffer(b, "")
  end

  def self.process(file: nil, buffer: nil, **opts)
    vimg = if file
             self.from_file(file)
    elsif buffer
      self.from_buffer(buffer)
    else
      raise ArgumentError, "file or buffer must be provided"
    end
    ip = self.prepare(vimg, **opts)
    return ip.call
  end

  # @param [Vips::Image] vips_img
  # @param [Float,Integer] w must be > 0, <= 1 is proportional resize, >1 and up is absolute size
  # @param [Float,Integer] h see w
  # @param [Symbol] format See FORMAT_VALUES
  # @param [Symbol] resize See RESIZE_VALUES
  # @param [Symbol] crop See CROP_VALUES
  # @param [Integer] quality Output format quality, when supported.
  # @param [Array<Float>] flatten Background color when removing alpha.
  def self.prepare(vips_img, w: nil, h: nil, format: nil, crop: nil, resize: nil, quality: nil, flatten: nil)
    v = ImageProcessing::Vips.source(vips_img)
    if w || h
      raise InvalidOption.new("width", w) if w && w <= 0
      raise InvalidOption.new("height", h) if h && h <= 0

      imw, imh = vips_img.size
      w = imw * w if w && w <= 1
      h = imh * h if h && h <= 1

      crop ||= CROP_VALUES.first
      raise InvalidOption.new("crop", crop) unless CROP_VALUES.include?(crop)
      crop = :centre if crop == :center

      resize ||= RESIZE_VALUES.first
      raise InvalidOption.new("resize", resize) unless RESIZE_VALUES.include?(resize)

      v = v.send("resize_to_#{resize}", w, h, crop:)
    end
    if quality
      raise InvalidOption.new("quality", quality) unless (1..100).cover?(quality)
      v = v.saver(quality:)
    end
    if flatten
      raise InvalidOption.new("flatten", flatten) unless flatten.length == 3
      v = v.flatten(background: flatten)
    end
    if format
      raise InvalidOption.new("format", format) unless FORMAT_VALUES.include?(format)
      v = v.convert(format.to_s)
    end
    return v
  end
end
