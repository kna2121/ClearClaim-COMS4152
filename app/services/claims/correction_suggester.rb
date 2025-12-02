module Claims
  # Maps denial codes or tuple payloads to denial explanations and recommended fixes.
  class CorrectionSuggester
    def initialize(denial_codes:)
      # Normalize whatever payload the caller sent into a consistent context hash.
      @contexts = Array(denial_codes).map { |entry| normalize_entry(entry) }.compact
    end

    # Returns a suggestion hash for each context or a fallback response if nothing is found.
    def call
      contexts.map do |context|
        rule = fetch_rule(context)
        next fallback_response(context) unless rule

        build_response(context, rule)
      end
    end

    private

    attr_reader :contexts

    # Lazily initialize the repository so we can reuse it across lookups.
    def repository
      @repository ||= DenialRules::Repository.new
    end

    # Accepts strings, arrays, or hashes and produces a normalized context hash.
    def normalize_entry(entry)
      case entry
      when Array
        remit_raw, remark_raw = entry
        # ERA remit strings (e.g. "CO29") carry both group and reason codes.
        group_code, reason_code = split_remit_code(remit_raw)
        remark_code = normalize_code(remark_raw)

        context = {}
        # Compose full remit code (e.g. CO29) to improve direct lookups.
        context[:code] = "#{group_code}#{reason_code}" if group_code.present? && reason_code.present?
        context[:group_code] = group_code if group_code.present?
        context[:reason_code] = reason_code if reason_code.present?
        context[:remark_code] = remark_code if remark_code.present?
        context.presence
      when Hash
        # Support both symbol and string keys from JSON payloads.
        code = normalize_code(entry[:code] || entry["code"], preserve_numeric: true)
        group_code = normalize_code(entry[:group_code] || entry["group_code"])
        reason_code = normalize_code(entry[:reason_code] || entry["reason_code"], preserve_numeric: true)
        remark_code = normalize_code(entry[:remark_code] || entry["remark_code"])

        context = {}
        context[:code] = code if code.present?
        context[:group_code] = group_code if group_code.present?
        context[:reason_code] = reason_code if reason_code.present?
        context[:remark_code] = remark_code if remark_code.present?
        context.presence
      else
        code = normalize_code(entry, preserve_numeric: true)
        code.present? ? { code: code } : nil
      end
    end

    def normalize_code(value, preserve_numeric: false)
      str = value.to_s.strip
      return nil if str.blank?
      return str if preserve_numeric && str.match?(/\A[0-9]+\z/)

      str.upcase
    end

    # Splits ERA remit codes like "CO29" into ["CO", "29"].
    def split_remit_code(value)
      normalized = value.to_s.strip.upcase
      return [nil, nil] if normalized.blank?

      # Some remits are already in "CO29" format; peel off the alpha prefix for group, remainder for reason.
      sanitized = normalized.gsub(/\s+/, "")
      match = sanitized.match(/\A([A-Z]{2})([A-Z0-9]+)?\z/)
      return [normalize_code(sanitized), nil] unless match

      group = match[1]
      reason = match[2]
      reason = nil if reason.blank?
      [group, reason]
    end

    # Query downstream repository for the best match based on available keys.
    def fetch_rule(context)
      repository.fetch_by_context(
        code: context[:code],
        group_code: context[:group_code],
        reason_code: context[:reason_code],
        remark_code: context[:remark_code]
      )
    end

    # Format a repository rule into the API response shape.
    def build_response(context, rule)
      {
        # Prefer the stored EOB code when we have a rule; otherwise fall back to the provided value.
        code: rule["code"].presence || context[:code],
        group_code: rule["group_code"].presence || context[:group_code],
        reason_code: context[:reason_code].presence || Array(rule["reason_codes"]).first,
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

    # Provide conservative default guidance when nothing matched upstream.
    def fallback_response(context)
      {
        code: nil,
        group_code: context[:group_code],
        reason_code: context[:reason_code],
        remark_code: context[:remark_code],
        reason: "No rule found. Escalate to manual review.",
        suggested_correction: "Verify documentation and payer requirements.",
        documentation: []
      }
    end
  end
end
