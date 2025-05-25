# frozen_string_literal: true

require "suma/fixtures"
require "suma/uploaded_file"
require "mimemagic"

module Suma::Fixtures::UploadedFiles
  extend Suma::Fixtures

  fixtured_class Suma::UploadedFile

  base :uploaded_file do
    self.opaque_id ||= Suma::Secureid.new_opaque_id("im")
    self.content_type ||= ["image/png", "image/jpeg", "application/pdf"].sample
    self.content_length ||= Faker::Number.between(from: 64, to: 1024)
    self.sha256 ||= ::Digest::SHA256.hexdigest(SecureRandom.bytes(self.content_length))
    self.filename ||= "#{self.opaque_id}.#{self.content_type.split('/').last}"
  end

  decorator :uploaded_1x1_png do
    fields = Suma::UploadedFile.fields_with_blob(bytes: Suma::SpecHelpers::PNG_1X1_BYTES, content_type: "image/png")
    fields[:filename] = "#{self.opaque_id}.png"
    self.set(fields)
  end

  decorator :uploaded_bytes do |bytes, content_type, filename: nil, **kw|
    fields = Suma::UploadedFile.fields_with_blob(bytes:, content_type:, **kw)
    fields[:filename] = filename || "#{self.opaque_id}.#{content_type.split('/').last}"
    self.set(fields)
  end

  decorator :uploaded_file do |f|
    content_type = MimeMagic.by_magic(File.open(f.path)).type
    fields = Suma::UploadedFile.fields_with_blob(bytes: f.read, content_type:)
    fields[:filename] = Pathname(f.path).basename.to_s
    self.set(fields)
  end

  decorator :private do |created_by=nil|
    created_by ||= Suma::Fixtures.member.create
    self.private = true
    self.created_by = created_by
  end
end
