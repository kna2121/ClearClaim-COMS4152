# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home page', type: :feature do
  scenario 'displays a welcome message' do
    visit root_path
    expect(page).to have_content('AI Appeal Assistant')
  end
end
