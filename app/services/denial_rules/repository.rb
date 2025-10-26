require "yaml"

module DenialRules
  # Repository can read from the database first and fall back to YAML-defined rules.
  class Repository
    def initialize(path: default_path)
      @path = path
    end

    def fetch(code)
      normalized_code = normalize(code)
      return nil if normalized_code.blank?

      database_rule_by_code(normalized_code) || yaml_rules[normalized_code]
    end

    def fetch_by_group_and_remark(group_code, remark_code)
      normalized_group = normalize(group_code)
      normalized_remark = normalize(remark_code)
      return nil if normalized_group.blank? && normalized_remark.blank?

      database_rule_by_group_and_remark(normalized_group, normalized_remark) ||
        yaml_rule_by_group_and_remark(normalized_group, normalized_remark)
    end

    def all
      yaml_rules.merge(database_rules_index)
    end

    private

    attr_reader :path

    def normalize(value)
      str = value.to_s.strip
      str.present? ? str.upcase : nil
    end

    def database_rule_by_code(code)
      return nil unless table_ready?

      record = DenialReason.find_by(code: code)
      record&.to_rule_hash
    end

    def database_rule_by_group_and_remark(group_code, remark_code)
      return nil unless table_ready?

      scope = DenialReason.all
      scope = scope.where(group_code: group_code) if group_code.present?
      scope = scope.where(remark_code: remark_code) if remark_code.present?
      record = scope.first
      record&.to_rule_hash
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

    def yaml_rule_by_group_and_remark(group_code, remark_code)
      yaml_rules.values.find do |rule|
        matches_group = group_code.present? ? rule["group_code"].to_s.upcase == group_code : true
        matches_remark = remark_code.present? ? rule["remark_code"].to_s.upcase == remark_code : true
        matches_group && matches_remark
      end
    end

    def default_path
      Rails.root.join("config", "denial_rules.yml")
    end
  end
end
