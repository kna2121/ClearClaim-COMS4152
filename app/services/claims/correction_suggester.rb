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

        {
          code: code,
          reason: rule["reason"],
          suggested_correction: rule["suggested_correction"],
          documentation: rule["documentation"]
        }
      end
    end

    private

    attr_reader :denial_codes

    def repository
      @repository ||= DenialRules::Repository.new
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
