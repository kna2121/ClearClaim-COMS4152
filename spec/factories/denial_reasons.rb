FactoryBot.define do
  factory :denial_reason do
    sequence(:code) { |n| format("%03d", n) }
    description { "Sample denial reason #{code}" }
    group_code { "CO" }
    rejection_code { nil }
    remark_code { nil }
    reason_codes { [] }
    suggested_correction { nil }
    documentation { [] }
  end
end
