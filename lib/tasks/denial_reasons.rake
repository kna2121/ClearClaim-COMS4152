require "csv"
require "fileutils"

namespace :denial_reasons do
  # Shared helpers between rake task and seeds ensure consistent normalization.
  def sanitize_field(value)
    value.to_s.strip.presence
  end

  def sanitize_code(value)
    str = value.to_s.strip
    str.present? ? str.upcase : nil
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

  desc "Import denial reasons from the GA EOB CSV (default: config/EOBList.csv)"
  task :import_eob, [:path] => :environment do |_t, args|
    path = args[:path] || Rails.root.join("config", "EOBList.csv")
    abort "CSV not found at #{path}" unless File.exist?(path)

    imported = 0
    # Mirror db/seeds logic so ops can refresh data without redeploying.
    CSV.foreach(path, headers: true) do |row|
      code = sanitize_field(row["EOB CODE"])
      next if code.blank?

      denial = DenialReason.find_or_initialize_by(code: code)
      denial.description = sanitize_field(row["DESCRIPTION"])
      denial.rejection_code = sanitize_code(row["Rejection Code"])
      denial.group_code = sanitize_code(row["Group Code"])
      denial.reason_codes = parse_codes(row["Reason Code"])
      denial.remark_code = sanitize_code(row["Remark Code"])
      denial.save!
      imported += 1
    end

    puts "Imported/updated #{imported} denial reasons from #{path}."
  end

  desc "Export denial reasons to CSV (default: tmp/denial_reasons.csv)"
  task :export_csv, [:path] => :environment do |_t, args|
    path = args[:path] || Rails.root.join("tmp", "denial_reasons.csv")
    FileUtils.mkdir_p(File.dirname(path))

    CSV.open(path, "wb") do |csv|
      csv << %w[EOB_CODE DESCRIPTION REJECTION_CODE GROUP_CODE REASON_CODES REMARK_CODE]
      DenialReason.find_each do |reason|
        csv << [
          reason.code,
          reason.description,
          reason.rejection_code,
          reason.group_code,
          reason.reason_codes.join(" "),
          reason.remark_code
        ]
      end
    end

    puts "Exported #{DenialReason.count} rows to #{path}."
  end
end
