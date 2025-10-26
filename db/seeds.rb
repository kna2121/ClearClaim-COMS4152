# frozen_string_literal: true

require "csv"

def sanitize_field(value)
  value.to_s.strip.presence
end

def parse_codes(value)
  sanitized = value.to_s.strip
  return [] if sanitized.blank?

  sanitized
    .gsub(/[^A-Za-z0-9, ]/, " ")
    .split(/[, ]/)
    .map { |code| code.strip.upcase }
    .reject(&:blank?)
end

csv_path = Rails.root.join("config", "EOBList.csv")

if File.exist?(csv_path)
  puts "Importing denial reasons from #{csv_path}..."
  CSV.foreach(csv_path, headers: true) do |row|
    code = sanitize_field(row["EOB CODE"])
    next if code.blank?

    denial = DenialReason.find_or_initialize_by(code: code)
    denial.description = sanitize_field(row["DESCRIPTION"])
    denial.rejection_code = sanitize_field(row["Rejection Code"])
    denial.group_code = sanitize_field(row["Group Code"])
    denial.reason_codes = parse_codes(row["Reason Code"])
    denial.remark_code = sanitize_field(row["Remark Code"])
    denial.save!
  end
  puts "Seeded #{DenialReason.count} denial reason rows."
else
  puts "EOB CSV not found at #{csv_path}; skipping denial reason import."
end
