# ClearClaim-COMS4152
ClearClaim: AI Appeal Assistant for Healthcare Denials  
Jalen Stephens (js5987)
Kira Ariyan (kna2121)
Zilin Jing (zj2398)
Darran Shivdat (dss2194)

# AI Appeal Assistant

This directory contains a Ruby on Rails 7 starter application tailored for the AI Appeal Assistant SaaS product. It includes RSpec and Cucumber wiring so you can immediately begin implementing features and acceptance tests.

## Getting Started

1. Ensure you have Ruby 3.4.5 installed.
2. Install dependencies:

   ```bash
   bundle install
   ```

3. Set up the database:

   ```bash
   bin/rails db:setup
   ```

4. Run the Rails server:

   ```bash
   bin/rails server
   ```

## Appeal Assistant Architecture

- **Document intake** – `Claims::DocumentAnalyzer` routes uploads to `Claims::PdfAnalyzer` (pdf-reader/combine_pdf) or `Claims::OcrReader` (rtesseract) for text extraction.
- **Rule mapping** – `DenialRules::Repository` loads `config/denial_rules.yml`, powering `Claims::CorrectionSuggester` so denial codes map to explanations/corrections without a DB round-trip.
- **Appeal drafting** – `Appeals::AppealGenerator` renders ERB templates (see `app/views/appeals/templates`) and leaves a hook to call LLM APIs before exporting via Prawn/Caracal.
- **Storage targets** – PostgreSQL remains the system of record for claims/denials; ActiveStorage (with S3/GCS/Azure) should store original PDFs and generated appeals once wired up.
- **Async/AI** – Sidekiq is included so heavy OCR, PDF builds, or LLM calls can move to background jobs in future iterations.

## HTTP Endpoints

| Endpoint | Purpose | Required params |
| --- | --- | --- |
| `POST /claims/analyze` | Ingest a denied-claim PDF/image and return extracted metadata and denial codes. | `file` (multipart upload) |
| `POST /claims/suggest_corrections` | Map denial codes to reasons/corrections from YAML rules. | `denial_codes[]` |
| `POST /claims/generate_appeal` | Produce an appeal draft using claim payload + denial reasons. | `claim[...]`, `denial_codes[]`, optional `template` |

Example request to analyze a PDF:

```bash
curl -X POST http://localhost:3000/claims/analyze \
  -F "file=@spec/fixtures/files/sample_denial.pdf"
```

Example appeal generation:

```bash
curl -X POST http://localhost:3000/claims/generate_appeal \
  -H "Content-Type: application/json" \
  -d '{
    "claim": {
      "claim_number": "12345",
      "patient_name": "Jane Doe",
      "payer_name": "Clear Health",
      "service_period": "Jan 1-5 2024",
      "submitter_name": "ClearClaim Assistant"
    },
    "denial_codes": ["CO45", "PR204"]
  }'
```

## Configuring OCR & Rules

- Install Tesseract locally to unlock `Claims::OcrReader` (`brew install tesseract` on macOS).
- Edit `config/denial_rules.yml` to expand the denial reason library; the structure is `{ CODE: { reason:, suggested_correction:, documentation: [] } }` and can be migrated to a DB-backed rule engine later.
- Swap the appeal template or add new ones under `app/views/appeals/templates`, then pass `template` when calling `/claims/generate_appeal`.

## Testing

Run RSpec:

```bash
bundle exec rspec
```

Run Cucumber:

```bash
bundle exec cucumber
```

Both suites currently include a simple smoke test covering the landing page.
