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
    codes = params[:denial_codes] || []
    suggestions = Claims::CorrectionSuggester.new(denial_codes: codes).call
    render json: { suggestions: suggestions }
  end

  def generate_appeal
    claim_payload = claim_params.to_h.symbolize_keys
    denial_codes = params[:denial_codes] || []
    denial_reasons = Claims::CorrectionSuggester.new(denial_codes: denial_codes).call
    response = Appeals::AppealGenerator.new(
      claim: claim_payload,
      denial_reasons: denial_reasons,
      template: params[:template] || "default_letter"
    ).call

    render json: response
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
      :submitter_name
    )
  end
end
