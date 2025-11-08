
When("I click the upload area") do
    find("#upload-area").click
end

And("I upload {string}") do |filename|
  attach_file("pdf-input", Rails.root.join("spec/fixtures/files", filename))
end

Then("I should see the file name {string}") do |filename|
  using_wait_time 5 do 
    expect(page).to have_content(filename)
  end
end

And("I press {string}") do |button_text|
  using_wait_time 10 do # wait up to 10 seconds
    puts page.html
    expect(page).to have_button(button_text, disabled: false)
  end
  click_button(button_text)
end

Then("I should see {string}") do |expected_text|
  expect(page).to have_content(expected_text)
end
