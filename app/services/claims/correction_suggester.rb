module Claims
  # Maps denial codes or (group_code, remark_code) tuples to explanations and recommended fixes
  class CorrectionSuggester
    def initialize(denial_codes:)
      @contexts = Array(denial_codes).map { |entry| normalize_entry(entry) }.compact
    end

    def call
      contexts.map do |context|
        rule = fetch_rule(context)
        next fallback_response(context) unless rule

        build_response(context, rule)
      end
    end

    private

    attr_reader :contexts

    def repository
      @repository ||= DenialRules::Repository.new
    end

    def normalize_entry(entry)
      case entry
      when Array
        group_code = normalize_code(entry[0])
        remark_code = normalize_code(entry[1])
        return nil if group_code.blank? && remark_code.blank?

        { group_code: group_code, remark_code: remark_code }
      when Hash
        code = normalize_code(entry[:code] || entry["code"], preserve_numeric: true)
        group_code = normalize_code(entry[:group_code] || entry["group_code"])
        remark_code = normalize_code(entry[:remark_code] || entry["remark_code"])
        return nil if code.blank? && group_code.blank? && remark_code.blank?

        { code: code, group_code: group_code, remark_code: remark_code }
      else
        code = normalize_code(entry, preserve_numeric: true)
        return nil if code.blank?

        { code: code }
      end
    end

    def normalize_code(value, preserve_numeric: false)
      str = value.to_s.strip
      return nil if str.blank?
      return str if preserve_numeric && str.match?(/\A[0-9]+\z/)

      str.upcase
    end

    def fetch_rule(context)
      if context[:group_code].present? || context[:remark_code].present?
        repository.fetch_by_group_and_remark(context[:group_code], context[:remark_code]) ||
          repository.fetch(context[:code])
      else
        repository.fetch(context[:code])
      end
    end

    def build_response(context, rule)
      {
        code: context[:code] || rule["code"],
        group_code: context[:group_code].presence || rule["group_code"],
        remark_code: context[:remark_code].presence || rule["remark_code"],
        description: rule["description"] || rule["reason"],
        reason: rule["reason"],
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

    def fallback_response(context)
      {
        code: context[:code],
        group_code: context[:group_code],
        remark_code: context[:remark_code],
        reason: "No rule found. Escalate to manual review.",
        suggested_correction: "Verify documentation and payer requirements.",
        documentation: []
      }
    end
  end
end
