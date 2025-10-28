require "yaml"

module DenialRules
  # Repository can read from the database first and fall back to YAML-defined rules.
  class Repository
    def initialize(path: default_path)
      @path = path
    end

    def fetch(code)
      fetch_by_context(code: code)
    end

    def fetch_by_context(code: nil, group_code: nil, reason_code: nil, remark_code: nil)
      normalized_code = normalize(code)
      normalized_group = normalize(group_code)
      normalized_reason = normalize(reason_code, preserve_numeric: true)
      normalized_remark = normalize(remark_code)

      database_rule_by_code(normalized_code) ||
        database_rule_by_group_and_remark(normalized_group, normalized_remark) ||
        database_rule_by_group_and_reason(normalized_group, normalized_reason) ||
        database_rule_by_remark(normalized_remark) ||
        yaml_rule_by_code(normalized_code) ||
        yaml_rule_by_group_and_remark(normalized_group, normalized_remark) ||
        yaml_rule_by_group_and_reason(normalized_group, normalized_reason)
    end

    def all
      yaml_rules.merge(database_rules_index)
    end

    private

    attr_reader :path

    def normalize(value, preserve_numeric: false)
      str = value.to_s.strip
      return nil if str.blank?
      return str if preserve_numeric && str.match?(/\A[0-9]+\z/)

      str.upcase
    end

    def database_rule_by_code(code)
      return nil unless table_ready?
      return nil if code.blank?

      DenialReason.find_by(code: code)&.to_rule_hash
    end

    def database_rule_by_group_and_remark(group_code, remark_code)
      return nil unless table_ready?
      return nil if group_code.blank? && remark_code.blank?

      scope = DenialReason.all
      scope = scope.where(group_code: group_code) if group_code.present?
      scope = scope.where(remark_code: remark_code) if remark_code.present?
      scope.first&.to_rule_hash
    end

    def database_rule_by_group_and_reason(group_code, reason_code)
      return nil unless table_ready?
      return nil if reason_code.blank?

      scope = DenialReason.all
      scope = scope.where(group_code: group_code) if group_code.present?
      record = scope.find do |denial|
        Array(denial.reason_codes).map { |code| normalize(code, preserve_numeric: true) }.include?(reason_code)
      end
      record&.to_rule_hash
    end

    def database_rule_by_remark(remark_code)
      return nil unless table_ready?
      return nil if remark_code.blank?

      DenialReason.find_by(remark_code: remark_code)&.to_rule_hash
    end

    def database_rules_index
      return {} unless table_ready?

      DenialReason.all.each_with_object({}) do |record, memo|
        memo[record.code.to_s.upcase] = record.to_rule_hash
      end
    end

    def table_ready?
      DenialReason.table_exists?
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
      false
    end

    def yaml_rules
      @yaml_rules ||= begin
        raw = YAML.load_file(path) || {}
        raw.transform_keys { |key| key.to_s.upcase }
      rescue Errno::ENOENT
        {}
      end
    end

    def yaml_rule_by_code(code)
      return nil if code.blank?

      yaml_rules[code]
    end

    def yaml_rule_by_group_and_remark(group_code, remark_code)
      yaml_rules.values.find do |rule|
        matches_group = group_code.present? ? rule["group_code"].to_s.upcase == group_code : true
        matches_remark = remark_code.present? ? rule["remark_code"].to_s.upcase == remark_code : true
        matches_group && matches_remark
      end
    end

    def yaml_rule_by_group_and_reason(group_code, reason_code)
      return nil if reason_code.blank?

      yaml_rules.values.find do |rule|
        matches_group = group_code.present? ? rule["group_code"].to_s.upcase == group_code : true
        reasons = Array(rule["reason_codes"]).map { |code| normalize(code, preserve_numeric: true) }
        matches_group && reasons.include?(reason_code)
      end
    end

    def default_path
      Rails.root.join("config", "denial_rules.yml")
    end
  end
end
