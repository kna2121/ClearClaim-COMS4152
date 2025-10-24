require "yaml"

module DenialRules
  # Tiny abstraction over YAML-based rules, ready for future DB/engine swap
  class Repository
    def initialize(path: default_path)
      @path = path
    end

    def fetch(code)
      rules[code.to_s.upcase]
    end

    def all
      rules
    end

    private

    attr_reader :path

    def rules
      @rules ||= YAML.load_file(path)
    rescue Errno::ENOENT
      {}
    end

    def default_path
      Rails.root.join("config", "denial_rules.yml")
    end
  end
end
