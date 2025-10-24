require "erb"

module Appeals
  # Assembles an appeal draft and leaves hooks for LLM polishing/export
  class AppealGenerator
    TEMPLATE_ROOT = Rails.root.join("app", "views", "appeals", "templates")

    def initialize(claim:, denial_reasons:, template: "default_letter")
      @claim = claim
      @denial_reasons = denial_reasons
      @template = template
    end

    def call
      rendered = render_template
      polished = polish_with_llm(rendered)
      {
        format: :text,
        body: polished,
        metadata: {
          template: template,
          polish: "llm_placeholder"
        }
      }
    end

    private

    attr_reader :claim, :denial_reasons, :template

    def render_template
      template_path = TEMPLATE_ROOT.join("#{template}.erb")
      raise ArgumentError, "template #{template} not found" unless File.exist?(template_path)

      ERB.new(File.read(template_path)).result(binding)
    end

    def polish_with_llm(body)
      # Slot in OpenAI/Anthropic or an internal model here.
      body
    end
  end
end
