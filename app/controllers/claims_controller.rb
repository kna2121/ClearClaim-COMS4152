# frozen_string_literal: true

class ClaimsController < ApplicationController
  skip_forgery_protection

  def analyze
    result = Claims::DocumentAnalyzer.new(file: params[:file]).call
    render json: { claim: result }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def suggest_corrections
    # Accept both legacy `denial_codes` arrays and the new `denials` tuple payloads
    suggestions = Claims::CorrectionSuggester.new(denial_codes: denial_payload).call
    render json: { suggestions: suggestions }
  end

  def generate_appeal
    request.format = :json
    claim_payload = claim_params.to_h.symbolize_keys
    denial_reasons = Claims::CorrectionSuggester.new(denial_codes: denial_payload).call
    puts 
    appeal_result = Appeals::AppealGenerator.new(
      claim: claim_payload,
      denial_reasons: denial_reasons,
    ).call
    
    if appeal_result[:error].present?
      render json: { error: appeal_result[:error] }, status: :unprocessable_entity
    else
      render json: appeal_result
    end
    
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def claim_params
    params.require(:claim).permit(
      :claim_number,
      :patient_name,
      :payer_name,
      :service_period,
      :submitter_name,
      :source,
      :raw_text,
      denial_codes: [],
      demographics: {},
      line_items: [
        :service_date,
        :procedure_code,
        :billed,
        :allowed,
        :paid,
        { remit_codes: [], remark_codes: [] }
      ]
    )
  end



  def denial_payload
    # Support both `denials` (tuple arrays) and `denial_codes` (legacy strings).
    params[:denials] || params[:denial_codes] || []
  end
end
