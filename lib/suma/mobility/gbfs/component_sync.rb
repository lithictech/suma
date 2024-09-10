# frozen_string_literal: true

class Suma::Mobility::Gbfs::ComponentSync
  # @param client [Suma::Mobility::Gbfs::Client]
  def before_sync(client); end
  def model = raise NotImplementedError
  def yield_rows(_vendor_service) = raise NotImplementedError
  def external_id_column = raise NotImplementedError
end
