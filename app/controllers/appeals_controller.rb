# app/controllers/appeals_controller.rb
class AppealsController < ApplicationController
  def show
    @appeal_letter = params[:content]
    render :appeal_letter
  end
end
