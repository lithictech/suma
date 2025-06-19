# frozen_string_literal: true

class Suma::Message::Forwarder
  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:message_forwarder) do
    setting :phone_numbers, [], convert: ->(s) { s.split.map(&:strip) }
    setting :front_inbox_id, ""
  end

  class << self
    def configured? = self.front_inbox_id.present?
  end

  def initialize(now:)
    @now = now
  end

  def run
    raise Suma::InvalidPrecondition, "NUMBER_FORWARDER_PHONE_NUMBERS must be set" unless
      self.class.configured?
    rows = self.fetch_rows
    results = []
    rows.each do |row|
      Suma::Idempotency.once_ever.under_key("sw-forwarder-#{row.fetch(:signalwire_id)}") do
        results << self.import_row(row)
      end
    end
    return results
  end

  def import_row(row)
    body = row.fetch(:data).fetch("body")
    body = "<blank>" if body.blank?
    attachments = []
    if row.fetch(:data).fetch("num_media").positive?
      media_url = row.fetch(:data).fetch("subresource_uris").fetch("media")
      media_resp = Suma::Signalwire.make_rest_request(:get, media_url)
      # Save attachments into tempfiles so they will be uploaded properly as part of a multipart request to Front.
      # Use a tempdir so we can get predictable filenames.
      tempdir = Dir.mktmpdir("suma-msg-importer")
      media_resp.fetch("media_list").each_with_index do |image, i|
        body_resp = Suma::Signalwire.make_rest_request(
          :get,
          image.fetch("uri").delete_suffix(".json"),
          headers: {"Accept" => "*/*"}, # Needed to download non-JSON
        )
        filename = row.fetch(:date_created).strftime("%Y%m%d")
        filename += "-attachment#{i + 1}"
        filename += "." + image.fetch("content_type").split("/").last
        attachment = File.open(Pathname(tempdir) + filename, "wb+")
        attachment.write(body_resp)
        attachment.rewind
        attachments << attachment
      end
      # Turn an array ['x', 'y'] into a Hash {0=>'x', 1=>'y'} so we get 'attachments[0]' in form-data.
      attachments = attachments.each_with_index.to_h { |a, i| [i, a] }
    end
    body = {
      sender: {
        handle: Suma::Frontapp.contact_phone_handle(row.fetch(:from)),
      },
      to: [Suma::Frontapp.contact_phone_handle(row.fetch(:from))],
      body:,
      external_id: row.fetch(:signalwire_id),
      created_at: row.fetch(:date_created).to_i,
      type: "sms",
      metadata: {
        is_inbound: true,
        is_archived: false,
      },
      attachments:,
    }
    Suma::Frontapp.make_http_request(
      :post,
      "/inboxes/#{Suma::Frontapp.to_inbox_id(self.class.front_inbox_id)}/imported_messages",
      body:,
      multipart: attachments.any?,
    )
  end

  def fetch_rows
    cutoff = @now - 1.week
    ds = Suma::Webhookdb.signalwire_messages_dataset
    ds = ds.where { date_created > cutoff }
    ds = ds.where(
      direction: "inbound",
      to: self.class.phone_numbers.map { |n| Suma::PhoneNumber.format_e164(n) },
    )
    ds = ds.order(:date_created)
    return ds.all
  end
end
