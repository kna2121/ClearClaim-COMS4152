# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Home page', type: :feature do
  scenario 'displays welcome message and branding' do
    visit root_path
    
    expect(page).to have_content('ClearClaim')
    expect(page).to have_content("Let's get started")
    expect(page).to have_content('Upload your claim document to begin analysis')
  end
  
  scenario 'displays upload interface' do
    visit root_path
    
    expect(page).to have_css('.upload-area')
    expect(page).to have_content('Choose a file or drag it here')
    expect(page).to have_content('PDF files only')
    expect(page).to have_content('Maximum size 10MB')
  end
  
  scenario 'has file input with correct attributes' do
    visit root_path
    
    expect(page).to have_css('input[type="file"][accept="application/pdf"]', visible: false)
  end
  
  scenario 'has disabled submit button initially' do
    visit root_path
    
    expect(page).to have_button('Analyze Document', disabled: true)
  end
  
  scenario 'displays upload icon' do
    visit root_path
    
    expect(page).to have_css('.upload-icon-wrapper svg')
  end
end