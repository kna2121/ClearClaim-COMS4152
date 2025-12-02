# frozen_string_literal: true

require "csv"

# Utility helpers mirror the rake task so both can share normalization logic.
def sanitize_field(value)
  value.to_s.strip.presence
end

def sanitize_code(value)
  str = value.to_s.strip
  str.present? ? str.upcase : nil
end

def primary_code(eob_code, group_code)
  code = sanitize_field(eob_code)
  group = sanitize_code(group_code)
  return nil if code.blank? && group.blank?
  return code if group.blank?

  # Drop leading zeros in the numeric portion so remit codes like CO3/CO29 match.
  normalized_code = code.sub(/\A0+/, "")
  normalized_code = code if normalized_code.blank? # keep original if it was all zeros

  "#{group}#{normalized_code}"
end

def parse_codes(value)
  sanitized = value.to_s.strip
  return [] if sanitized.blank?

  sanitized
    .gsub(/[^A-Za-z0-9, ]/, " ")
    .split(/[, ]/)
    .map { |code| code.strip.upcase }
    .reject(&:blank?)
    .uniq
end

csv_path = Rails.root.join("config", "EOBList.csv")

if File.exist?(csv_path)
  puts "Importing denial reasons from #{csv_path}..."
  CSV.foreach(csv_path, headers: true) do |row|
    # Each row mirrors the payer crosswalk; normalize the interesting bits and persist/update the record.
    code = primary_code(row["EOB CODE"], row["Group Code"])
    next if code.blank?

    denial = DenialReason.find_or_initialize_by(code: code)
    denial.description = sanitize_field(row["DESCRIPTION"])
    denial.rejection_code = sanitize_code(row["Rejection Code"])
    denial.group_code = sanitize_code(row["Group Code"])
    denial.reason_codes = parse_codes(row["Reason Code"])
    denial.remark_code = sanitize_code(row["Remark Code"])
    denial.save!
  end
  puts "Seeded #{DenialReason.count} denial reason rows."
else
  puts "EOB CSV not found at #{csv_path}; skipping denial reason import."
end
