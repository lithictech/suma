# frozen_string_literal: true

require "suma/fixtures"
require "suma/uploaded_file"

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
    fields = Suma::UploadedFile.fields_with_blob(bytes: PNG_1X1_BYTES, content_type: "image/png")
    self.set(fields)
  end

  decorator :uploaded_bytes do |bytes, content_type|
    fields = Suma::UploadedFile.fields_with_blob(bytes:, content_type:)
    self.set(fields)
  end

  decorator :uploaded_file do |f|
    content_type = MIME::Types.type_for(f.path).first.to_s
    fields = Suma::UploadedFile.fields_with_blob(bytes: f.read, content_type:)
    self.set(fields)
  end

  PNG_1X1_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAABXWlDQ1BJQ0MgUHJvZmlsZQAAKJFtkDFLw1AUhU+0UmiDWFoEoUgcFIRaSnRyqxWq2CFUi1pwSF9rIrTxkUTESXdxUfEniD9A6OIgCM6CoODkpD9A6KIl3teoadUHl/txOPe+ywH6ZJ3zeghAw3LtYn5OWVsvK+EXRBCDjFHEdebwrKYVyILv3vtaD5BEv58Su9hS3EqP3I5LJ4f7r8mx+F9/z4tUaw6j/kGlMm67gJQh1nZdLviAOGHTUcSngg2fLwRXfL7qeFaKOeI74iFm6lXiZ+JUpUs3urhR32FfN4jr5ZpVWqY+TJVEAXkoKKEOFzZ04gXMU0b/z8x0ZnLYBsce+bdgwKRJBVlSOG2pES/CAkMaKWIVGSpVZP07w0BzKIfZI/qKB9pGArg0gUEWaBPHQCwK3JS5bus/yUqtkLM5rfocbQIDZ573tgqEJ4H2o+e9Nz2vfQ70PwHXrU92b2AplRAQjQAAADhlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAAaADAAQAAAABAAAAAQAAAADa6r/EAAAAC0lEQVQIHWNgAAIAAAUAAY27m/MAAAAASUVORK5CYII=" # nolen
  PNG_1X1_BYTES = Base64.decode64(PNG_1X1_BASE64)
end
