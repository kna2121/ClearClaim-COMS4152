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
- **Rule mapping** – `DenialRules::Repository` reads from the `denial_reasons` table (populated via `config/EOBList.csv`) and falls back to `config/denial_rules.yml` so payer logic can change without redeploys.
- **Appeal drafting** – `Appeals::AppealGenerator` renders ERB templates (see `app/views/appeals/templates`) and leaves a hook to call LLM APIs before exporting via Prawn/Caracal.
- **Storage targets** – PostgreSQL remains the system of record for claims/denials; ActiveStorage (with S3/GCS/Azure) should store original PDFs and generated appeals once wired up.
- **Async/AI** – Sidekiq is included so heavy OCR, PDF builds, or LLM calls can move to background jobs in future iterations.

## HTTP Endpoints

| Endpoint | Purpose | Required params |
| --- | --- | --- |
| `POST /claims/analyze` | Ingest a denied-claim PDF/image and return extracted metadata and denial codes. | `file` (multipart upload) |
| `POST /claims/suggest_corrections` | Map denial/EOB codes (or `[group_code, remark_code]` tuples) to stored reasons/corrections. | `denial_codes[]` |
| `POST /claims/generate_appeal` | Produce an appeal draft using claim payload + denial reasons. | `claim[...]`, `denial_codes[]`, optional `template` |

Example request to analyze a PDF:

```bash
curl -X POST http://localhost:3000/claims/analyze \
  -F "file=@spec/fixtures/files/sample_denial.pdf"
```

Example correction lookup with tuple payload:

```bash
curl -X POST http://localhost:3000/claims/suggest_corrections \
  -H "Content-Type: application/json" \
  -d '{
    "denial_codes": [
      ["CO29", "N211"],
      ["PR3", null]
    ]
  }'
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
- Maintain denial data primarily via the `denial_reasons` table (see next section); `config/denial_rules.yml` remains as a lightweight fallback for quick overrides.
- Swap the appeal template or add new ones under `app/views/appeals/templates`, then pass `template` when calling `/claims/generate_appeal`.

## Denial Reason Database

- Run `bin/rails db:migrate` to create the `denial_reasons` table with columns for EOB code (`code`), payer description, rejection code, group code, parsed reason codes (array), remark code, suggested corrections, and documentation.
- Keep the GA EOB crosswalk (or any payer-provided spreadsheet) in `config/EOBList.csv`. Seed the table via `bin/rails db:seed` or manually import with `bin/rails denial_reasons:import_eob[/absolute/path/to/EOBList.csv]`.
- Each row in the CSV must include headers `EOB CODE, DESCRIPTION, Rejection Code, Group Code, Reason Code, Remark Code`; multiple reason codes in a single cell (e.g., `"A1, 45 N54"`) are automatically split into arrays.
- Export the curated DB for auditing/sharing with `bin/rails denial_reasons:export_csv[optional/output.csv]`.
- `Claims::CorrectionSuggester` consumes these records, so the REST API immediately reflects any newly imported or edited codes.

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
