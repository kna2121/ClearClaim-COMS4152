# frozen_string_literal: true

Given('I visit the home page') do
  visit root_path
end

Then('I should see {string}') do |expected_text|
  expect(page).to have_content(expected_text)
end
