# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'PDF Upload Feature', type: :feature do
  scenario 'user visits home page and sees upload interface' do
    visit root_path
    
    expect(page).to have_content("Let's get started")
    expect(page).to have_content('Upload your claim document to begin analysis')
    expect(page).to have_content('Choose a file or drag it here')
    expect(page).to have_content('PDF files only')
  end
  
  scenario 'displays ClearClaim branding' do
    visit root_path
    expect(page).to have_content('ClearClaim')
  end
  
  scenario 'has analyze button (disabled initially)' do
    visit root_path
    # Button exists but is disabled by default
    expect(page).to have_css('#submit-btn[disabled]', text: 'Analyze Document')
  end
  
  scenario 'has file upload input' do
    visit root_path
    expect(page).to have_css('input[type="file"][accept="application/pdf"]', visible: false)
  end
end