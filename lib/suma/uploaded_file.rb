# frozen_string_literal: true

require "appydays/configurable"
require "mimemagic"

class Suma::UploadedFile < Suma::Postgres::Model(:uploaded_files)
  include Appydays::Configurable
  extend Suma::MethodUtilities

  class MissingBlob < StandardError; end
  class PrivateFile < StandardError; end

  plugin :timestamps

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

  def self.fields_with_blob(bytes:, content_type:)
    opaque_id = Suma::Secureid.new_opaque_id("im")
    sha256 = self.upsert_blob(bytes:)
    return {sha256:, opaque_id:, content_type:, content_length: bytes.size}
  end

  def self.create_with_blob(bytes:, content_type:, **params)
    fields = self.fields_with_blob(bytes:, content_type:)
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
    if @_blob_bytes.nil? || @_blob_bytes_hash != self.sha256
      @_blob_bytes = self.class.blob_dataset.where(sha256: self.sha256).select_map(:bytes).first
      raise MissingBlob, "no blob in database for #{self.sha256}" if @_blob_bytes.nil?
      @_blob_bytes_hash = self.sha256
    end
    return StringIO.new(@_blob_bytes)
  end

  def absolute_url
    return "#{Suma.api_url}/v1/images/#{self.opaque_id}"
  end

  def validate
    super
    errors.add(:private, "created_by must be set") if self.private? && self.created_by_id.nil?
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
# Indexes:
#  uploaded_files_pkey          | PRIMARY KEY btree (id)
#  uploaded_files_opaque_id_key | UNIQUE btree (opaque_id)
# Foreign key constraints:
#  uploaded_files_created_by_id_fkey | (created_by_id) REFERENCES members(id)
# Referenced By:
#  images | images_uploaded_file_id_fkey | (uploaded_file_id) REFERENCES uploaded_files(id)
# -----------------------------------------------------------------------------------------
