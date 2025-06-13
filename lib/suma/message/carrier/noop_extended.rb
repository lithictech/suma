# frozen_string_literal: true

class Suma::Message::Carrier::NoopExtended < Suma::Message::Carrier
  def key = "noop_ext"

  def send!(delivery_id:) = "noopext-#{delivery_id}-#{SecureRandom.hex(6)}"

  def decode_message_id(msg_id) = msg_id.gsub("^noopext-", "")
  def external_link_for(msg_id) = "https://fakecarrier/#{msg_id}"
  def can_fetch_details? = true
  def fetch_message_details(msg_id) = {"noop_msg_id" => msg_id}
end
