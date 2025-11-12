# frozen_string_literal: true
require "openai"
require "erb"

module Appeals
  class AppealGenerator
    def initialize(claim:, denial_reasons:)
      @claim = claim
      @denial_reasons = denial_reasons
    end

    def call
      # In test or when no API key is set, render a local template
      if Rails.env.test? || (ENV["OPENAI_API_KEY"].to_s.strip.empty? && ENV["OPENAI_ACCESS_TOKEN"].to_s.strip.empty?)
        return { appeal_letter: render_template }
      end

      prompt = build_prompt
      response_text = query_llm(prompt)
      { appeal_letter: response_text }
    rescue StandardError => e
      { error: "LLM generation failed: #{e.message}" } 
    end

    private

    def build_prompt
      <<~PROMPT
        You are an expert healthcare billing specialist.
        Generate a clear, professional insurance appeal letter based on the following information:

        Claim number: #{@claim[:claim_number]}
        Patient: #{@claim[:patient_name]}
        Payer: #{@claim[:payer_name]}
        Service period: #{@claim[:service_period]}
        Denial reasons: #{@denial_reasons.join(', ')}

        Use formal tone and clear formatting.
      PROMPT
   end

   def query_llm(prompt)
    client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: "You are a medical claim appeal assistant." },
          { role: "user", content: prompt }
        ],
        temperature: 0.6
      }
    )

    response.dig("choices", 0, "message", "content") || "No response from LLM"
  end

  def render_template
    template_path = Rails.root.join("app", "views", "appeals", "templates", "default_letter.erb")
    erb = ERB.new(File.read(template_path))
    claim = @claim
    denial_reasons = Array(@denial_reasons)
    erb.result_with_hash(claim: claim, denial_reasons: denial_reasons)
  end
  end
end
