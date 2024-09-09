# frozen_string_literal: true

class Suma::Mobility::Gbfs::ComponentSync
  # @param client [Suma::Mobility::Gbfs::Client]
  def before_sync(client); end
  def model = raise NotImplementedError
  def yield_rows(_vendor_service) = raise NotImplementedError
  def id_column = raise NotImplementedError
  def sync_columns = raise NotImplementedError
end
