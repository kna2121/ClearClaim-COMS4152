class DenialReason < ApplicationRecord
  validates :code, presence: true, uniqueness: true

  before_save :normalize_codes!

  def reason_text
    description.presence || "Reason details unavailable."
  end

  def to_rule_hash
    {
      "code" => code,
      "description" => description,
      "group_code" => group_code,
      "remark_code" => remark_code,
      "reason_codes" => reason_codes,
      "rejection_code" => rejection_code,
      "reason" => reason_text,
      "suggested_correction" => suggested_correction,
      "documentation" => documentation || []
    }
  end

  private

  def normalize_codes!
    self.code = code.to_s.strip if code.present?
    self.group_code = normalize_code(group_code)
    self.remark_code = normalize_code(remark_code)
    self.rejection_code = normalize_code(rejection_code)
    self.reason_codes = Array(reason_codes).map { |value| normalize_code(value) }.compact.uniq
  end

  def normalize_code(value)
    str = value.to_s.strip
    str.present? ? str.upcase : nil
  end
end
