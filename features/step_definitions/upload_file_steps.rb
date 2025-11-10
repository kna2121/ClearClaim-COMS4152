# frozen_string_literal: true

Given('I visit the home page') do
  visit root_path
end

Then('I should see {string}') do |expected_text|
  expect(page).to have_content(expected_text)
end

When("I upload {string}") do |filename|
  attach_file("pdf-input", Rails.root.join("spec/fixtures/files", filename), visible: false)
end

Then("the {string} button should become enabled") do |button_text|
  expect(page).to have_button(button_text, disabled: false)
end

And("I press {string}") do |button_text|
  using_wait_time 10 do
    expect(page).to have_button(button_text, disabled: false)
    click_button(button_text)
  end
end
