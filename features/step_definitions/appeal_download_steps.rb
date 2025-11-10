# frozen_string_literal: true

require "rack/utils"
require "zip"
require "stringio"
require "rexml/document"

Given("I have a generated appeal letter payload") do
  @letter_payload = <<~LETTER
    [Your Name]
    [Your Title]
    [Your Organization]
    [City, State, Zip]

    Dear Claims Review Department,

    Please contact me directly if any clarifications are required.
  LETTER
end

When("I request the appeal letter download as {string}") do |format|
  query = Rack::Utils.build_query(content: @letter_payload, format:)
  get("/appeal_letter?#{query}")
  @response = last_response
end

Then("the response should be a file download named {string}") do |prefix|
  disposition = @response.headers["Content-Disposition"]
  expect(disposition).to include("attachment")
  expect(disposition).to include(prefix)
end

Then("the download should be plain text including {string}") do |expected|
  expect(@response.headers["Content-Type"]).to include("text/plain")
  expect(@response.body).to include(expected)
end

Then("the download should be a docx file containing {string}") do |expected|
  expect(@response.headers["Content-Type"]).to include("application/vnd.openxmlformats-officedocument.wordprocessingml.document")
  text = extract_docx_text(@response.body)
  expect(text).to include(expected)
end

def extract_docx_text(binary)
  text = +""
  Zip::File.open_buffer(StringIO.new(binary)) do |zip|
    entry = zip.find_entry("word/document.xml")
    xml = entry.get_input_stream.read
    doc = REXML::Document.new(xml)
    doc.elements.each("//w:t") { |node| text << node.text.to_s }
  end
  text
end
