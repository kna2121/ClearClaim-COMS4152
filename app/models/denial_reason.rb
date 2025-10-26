class DenialReason < ApplicationRecord
  validates :code, presence: true, uniqueness: true

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
end
