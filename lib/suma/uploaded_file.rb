# frozen_string_literal: true

require "appydays/configurable"
require "mimemagic"

class Suma::UploadedFile < Suma::Postgres::Model(:uploaded_files)
  include Appydays::Configurable
  extend Suma::MethodUtilities

  class MissingBlob < StandardError; end
  class PrivateFile < StandardError; end
  class MismatchedContentType < StandardError; end

  plugin :timestamps
  plugin :immutable

  many_to_one :created_by, class: "Suma::Member"

  singleton_attr_reader :blob_database
  singleton_attr_reader :blob_table_ident

  def self.drop_blobs_table
    self.blob_database.drop_table?(@blob_table_ident)
  end

  def self.ensure_blobs_table
    self.blob_database.create_schema(@blob_table_schema, if_not_exists: true) if @blob_table_schema
    self.blob_database.create_table(@blob_table_ident, if_not_exists: true) do
      primary_key :pk
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      bytea :bytes, null: false
      text :sha256, null: false, unique: true
    end
  end

  configurable(:uploaded_files) do
    setting :blob_database_url, Suma::Postgres::Model.uri
    setting :blob_table, "uploaded_file_blobs"
    setting :blob_database_max_connections, Suma::Postgres::Model.max_connections
    setting :blob_database_pool_timeout, Suma::Postgres::Model.pool_timeout

    after_configured do
      @blob_database = Sequel.connect(
        self.blob_database_url,
        logger: [Suma.logger],
        sql_log_level: :debug,
        max_connections: self.blob_database_max_connections,
        pool_timeout: self.blob_database_pool_timeout,
      )
      if self.blob_table.include?(".")
        schema, table = self.blob_table.split(".")
        @blob_table_schema = Sequel[schema.to_sym]
        @blob_table_ident = @blob_table_schema[table.to_sym]
      else
        @blob_table_schema = nil
        @blob_table_ident = Sequel[self.blob_table.to_sym]
      end
      self.ensure_blobs_table
    end
  end

  def self.blob_dataset
    return self.blob_database[self.blob_table_ident]
  end

  def self.upsert_blob(bytes:)
    sha256 = ::Digest::SHA256.hexdigest(bytes)
    row = {bytes: Sequel::SQL::Blob.new(bytes), sha256:}
    self.blob_dataset.insert_conflict.insert(row)
    return sha256
  end

  def self.create_from_multipart(file, **params)
    bytes = file.fetch(:tempfile).read
    content_type = file[:type] || MimeMagic.by_path(file.fetch(:filename)).type || ""
    return self.create_with_blob(bytes:, content_type:, filename: file[:filename], **params)
  end

  def self.fields_with_blob(bytes:, content_type:, validate: true)
    opaque_id = Suma::Secureid.new_opaque_id("im")
    self._validate_content_types(bytes, content_type) if validate
    sha256 = self.upsert_blob(bytes:)
    return {sha256:, opaque_id:, content_type:, content_length: bytes.size}
  end

  # Before creating the file, validate that the given content type, and the magic number of the bytes,
  # agree, or are at least safe for use.
  def self._validate_content_types(bytes, ct)
    magic_ct = MimeMagic.by_magic(bytes)
    # Passed and actual match (or actual is more specific than passed), we're ok.
    return if magic_ct&.child_of?(ct)
    passed_ct = MimeMagic.new(ct)
    # Passed is text, but passed could not be detected. That's okay, since text usually doesn't have magic numbers.
    return if magic_ct.nil? && passed_ct.child_of?("text/plain")
    raise MismatchedContentType, "expected content type '#{ct}' does not match derived '#{magic_ct || '(nil)'}'"
  end

  def self.create_with_blob(bytes:, content_type:, validate: true, **params)
    fields = self.fields_with_blob(bytes:, content_type:, validate:)
    opts = fields.merge(params)
    opts[:filename] ||= "#{opts.fetch(:opaque_id)}.#{content_type.split('/').last}"
    self.create(opts)
  end

  # If true, +unlock_blob+ must be called to access +blob_stream+.
  # Usually, private blobs can only be read by the uploaded file's +created_by+ or admins.
  def private? = self.private

  # Allow +blob_stream+ to be called. See +private?+.
  def unlock_blob
    @unlocked_blob = true
    return self
  end

  def blob_stream
    if self.private? && !@unlocked_blob
      raise PrivateFile, "unlock_blob must be called on private files before accessing blob_stream"
    end
    return self.blob_stream_unsafe
  end

  # Read and return the blob stream, without checking for 'private' access.
  def blob_stream_unsafe
    if @_blob_bytes.nil? || @_blob_bytes_hash != self.sha256
      @_blob_bytes = self.class.blob_dataset.where(sha256: self.sha256).select_map(:bytes).first
      raise MissingBlob, "no blob in database for #{self.sha256}" if @_blob_bytes.nil?
      @_blob_bytes_hash = self.sha256
    end
    return StringIO.new(@_blob_bytes)
  end

  if Suma.test?
    # Provide an easy accessor for use in have_attributes matchers and general testing purposes.
    def read_blob_for_testing = self.blob_stream_unsafe.read
  end

  def absolute_url
    return "#{Suma.api_url}/v1/images/#{self.opaque_id}"
  end

  def validate
    super
    errors.add(:private, "created_by must be set") if self.private? && self.created_by_id.nil?
    validates_presence :filename
    self._validate_filename_content_type_match
  end

  def _validate_filename_content_type_match
    ext = File.extname(self.filename || "")
    filename_ct = MimeMagic.by_extension(ext)
    # We can't figure out the content type of the filename, so don't validate.
    return if filename_ct.nil?
    # If the filename is some type of the expected type, we're ok.
    return if filename_ct.child_of?(self.content_type)
    # If the expected type and the extension are the same, we're ok.
    # This is mostly an issue for .html files and text/html. .html can be one of many mime types.
    return if MimeMagic.new(self.content_type).subtype == ext[1..]
    errors.add(:filename, "#{ext} content type '#{filename_ct}' must match '#{self.content_type}'")
  end

  class NoImageAvailable
    class << self
      def data
        return @data if @data
        bytes = File.binread(Suma::DATA_DIR + "images/no-image-available.png")
        sha256 = ::Digest::SHA256.hexdigest(bytes)
        @data = {bytes:, sha256:}
        return @data
      end
    end

    def opaque_id = "missing"
    def filename = "no-image-available.png"
    def sha256 = self.class.data[:sha256]
    def content_type = "image/png"
    def content_length = self.class.data[:bytes].size
    def blob_stream = StringIO.new(self.class.data[:bytes])
    def absolute_url = "#{Suma.api_url}/v1/images/missing"
    def private? = false
  end
end

# Table: uploaded_files
# -----------------------------------------------------------------------------------------
# Columns:
#  id             | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at     | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at     | timestamp with time zone |
#  opaque_id      | text                     | NOT NULL
#  filename       | text                     | NOT NULL
#  sha256         | text                     | NOT NULL
#  content_type   | text                     | NOT NULL
#  content_length | integer                  | NOT NULL
#  created_by_id  | integer                  |
#  private        | boolean                  | NOT NULL DEFAULT false
# Indexes:
#  uploaded_files_pkey          | PRIMARY KEY btree (id)
#  uploaded_files_opaque_id_key | UNIQUE btree (opaque_id)
# Foreign key constraints:
#  uploaded_files_created_by_id_fkey | (created_by_id) REFERENCES members(id)
# Referenced By:
#  images | images_uploaded_file_id_fkey | (uploaded_file_id) REFERENCES uploaded_files(id)
# -----------------------------------------------------------------------------------------
