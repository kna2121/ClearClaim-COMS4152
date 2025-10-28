# frozen_string_literal: true
require "openai"

module Appeals
  class AppealGenerator
    def initialize(claim:, denial_reasons:, template:)
      @claim = claim
      @denial_reasons = denial_reasons
      @template = template
    end

    def call
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
    client = OpenAI::Client.new

    response = client.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          { role: "system", content: "You are a medical claim appeal assistant." },
          { role: "user", content: prompt }
        ],
        temperature: 0.6
      }
    )

    puts response.dig("choices", 0, "message", "content") || "No response from LLM"
  end


  end
end
