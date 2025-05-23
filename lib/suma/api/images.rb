# frozen_string_literal: true

require "suma/image_processor"
require "suma/api"

class Suma::API::Images < Suma::API::V1
  include Suma::Service::Types
  include Suma::API::Entities

  resource :images do
    route_param :opaque_id do
      helpers do
        def handle_response(uf, format: nil)
          env["api.format"] = :binary
          content_type(format ? "image/#{format}" : uf.content_type)
          header "Content-Disposition", "inline; filename=\"#{uf.filename}\""
          return yield
        end
      end
      params do
        optional :w, type: Float, values: 0.01..4096.0
        optional :h, type: Float, values: 0.01..4096.0
        optional :crop, type: Symbol, values: Suma::ImageProcessor::CROP_VALUES
        optional :resize, type: Symbol, values: Suma::ImageProcessor::RESIZE_VALUES
        # Use fmt, not format, since format is a Grape thing for the API response format.
        optional :fmt, type: Symbol, values: Suma::ImageProcessor::FORMAT_VALUES
        optional :q, type: Integer, values: 1..100
        optional :flatten, type: Array[Integer], coerce_with: CommaSepArray[Integer]
      end
      get do
        use_http_expires_caching 1.year
        format = params[:fmt]
        if params[:opaque_id] == "missing"
          uf = Suma::UploadedFile::NoImageAvailable.new
        else
          (uf = Suma::UploadedFile[opaque_id: params[:opaque_id]]) or forbidden!
        end
        if uf.private?
          if uf.created_by_id == current_member.id
            uf.unlock_blob
          else
            forbidden!
          end
        end
        if !params[:w] && !params[:h] && !format
          handle_response(uf) do
            uf.blob_stream.read
          end
        else
          # Use png as default so it works right with transparency.
          # However we need to do it here, not at the endpoint parameter level,
          # because we need to know when nothing is passed so we can read the underlying
          # file directly.
          format ||= :png
          result = Suma::ImageProcessor.process(
            buffer: uf.blob_stream.read,
            w: params[:w],
            h: params[:h],
            crop: params[:crop],
            resize: params[:resize],
            format:,
            quality: params[:q],
            flatten: params[:flatten],
          )
          handle_response(uf, format:) do
            stream result
          end
        end
      end
    end

    params do
      requires :file, type: File
    end
    post do
      created_by = current_member
      check_role_access!(created_by, :write, :upload_files)
      uf = Suma::UploadedFile.create_from_multipart(params[:file], created_by:)
      use_http_expires_caching(24.hours)
      status 200
      present uf, with: UploadedFileEntity
    end
  end

  class UploadedFileEntity < BaseEntity
    include Suma::API::Entities
    expose :opaque_id
    expose :content_type
    expose :content_length
    expose :absolute_url
  end
end
