# app/controllers/appeals_controller.rb
class AppealsController < ApplicationController
  def show
    @generated_at = Time.current
    @appeal_letter = normalize_letter(params[:content])
  end

  private

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
