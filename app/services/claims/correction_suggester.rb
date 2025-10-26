module Claims
  # Maps denial codes to explanations and recommended fixes
  class CorrectionSuggester
    def initialize(denial_codes:)
      @denial_codes = Array(denial_codes).compact.map(&:to_s)
    end

    def call
      denial_codes.map do |code|
        rule = repository.fetch(code)
        next fallback_response(code) unless rule

        build_response(code, rule)
      end
    end

    private

    attr_reader :denial_codes

    def repository
      @repository ||= DenialRules::Repository.new
    end

    def build_response(requested_code, rule)
      {
        code: requested_code,
        description: rule["description"] || rule["reason"],
        reason: rule["reason"],
        group_code: rule["group_code"],
        remark_code: rule["remark_code"],
        reason_codes: rule["reason_codes"],
        rejection_code: rule["rejection_code"],
        suggested_correction: rule["suggested_correction"].presence || default_suggestion(rule),
        documentation: rule["documentation"]
      }
    end

    def default_suggestion(rule)
      codes = Array(rule["reason_codes"]).presence
      if codes.present?
        "Review payer policy for codes #{codes.join(', ')} and include supporting documents."
      else
        "Review payer policy and include required supporting documents."
      end
    end

    def fallback_response(code)
      {
        code: code,
        reason: "No rule found. Escalate to manual review.",
        suggested_correction: "Verify documentation and payer requirements.",
        documentation: []
      }
    end
  end
end
