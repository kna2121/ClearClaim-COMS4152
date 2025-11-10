# app/controllers/appeals_controller.rb
class AppealsController < ApplicationController
  def show
    @generated_at = Time.current
    @appeal_letter = normalize_letter(params[:content])

    download_format = params[:format].presence&.to_sym || request.format.symbol

    if download_format.in?([:text, :txt, :docx])
      send_letter_download(download_format)
    else
      render :show
    end
  end

  private

  def send_letter_download(format)
    filename = "appeal_letter_#{Time.current.strftime('%Y%m%d_%H%M%S')}"
    body = @appeal_letter.presence || "No appeal letter generated."

    case format
    when :docx
      send_data(generate_docx(body), filename: "#{filename}.docx", type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document", disposition: "attachment")
    else
      send_data(body, filename: "#{filename}.txt", type: "text/plain", disposition: "attachment")
    end
  end

  def generate_docx(content)
    Tempfile.create(["appeal_letter", ".docx"]) do |file|
      Caracal::Document.save(file.path) do |doc|
        doc.h1 "Appeal Letter"
        doc.hr

        content.to_s.split(/\n{2,}/).each do |paragraph|
          next if paragraph.strip.blank?
          doc.p paragraph.strip
        end
      end

      file.rewind
      return file.read
    end
  end

  def normalize_letter(raw_content)
    return "" if raw_content.blank?

    letter_text =
      parse_json_payload(raw_content) ||
      parse_ruby_hash_payload(raw_content) ||
      raw_content

    letter_text.to_s.gsub("\\n", "\n").strip
  end

  def parse_json_payload(raw_content)
    parsed = JSON.parse(raw_content) rescue nil
    return unless parsed

    if parsed.is_a?(Hash)
      parsed["appeal_letter"] || parsed[:appeal_letter] || parsed.values.first
    else
      parsed
    end
  end

  def parse_ruby_hash_payload(raw_content)
    return unless raw_content.include?("=>")

    json_like = raw_content.gsub(/:(\w+)=>/, '"\1":').gsub("=>", ":")
    parse_json_payload(json_like)
  end
end
# frozen_string_literal: true

require "caracal"
