# ClearClaim-COMS4152
ClearClaim: AI Appeal Assistant for Healthcare Denials  
Jalen Stephens (js5987)
Kira Ariyan (kna2121)
Zilin Jing (zj2398)
Darran Shivdat (dss2194)

# AI Appeal Assistant

This directory contains a Ruby on Rails 7 starter application tailored for the AI Appeal Assistant SaaS product. It includes RSpec and Cucumber wiring so you can immediately begin implementing features and acceptance tests.

## Getting Started: Setup for Local Testing
(No set up required for deployed application)

1. Ensure you have Ruby 3.4.5 installed.
2. Install dependencies:

   ```bash
   bundle install
   ```
3. To run locally you need to set an environment variable with your openai api key. To avoid this, use the production version of ClearClaim on heroku (linked below).
   ```bash
   export OPENAI_API_KEY="your_key"
   ```
4. Set up the database (make sure postgresql is running on your machine):

   ```bash
   bin/rails db:setup
   ```
Note: If your local postgres configuration differs from the default, ensure it is configured as follows to avoid DB connection errors:
   ```bash
      export POSTGRES_USER="postgres"
      export POSTGRES_PASSWORD=""
      export POSTGRES_HOST="localhost"
   ```
This is only necessary if your postgres is not already configured this way.

5. Run the Rails server:

   ```bash
   bin/rails server
   ```
## Appeal Assistant Architecture

#### 1. 📤 **PDF Upload** (via API or Web Interface)
   - Accepts EOB documents in PDF format (digital or scanned)
   - Handles both machine-readable and image-based PDFs

#### 2. 🔍 **Intelligent Document Analysis** (`/claims/analyze`)
   - OCR-powered PDF parsing for EOB documents using RTesseract
   - Extracts patient demographics, billing codes, and denial reasons
   - Parses billing line items with service dates and amounts

#### 3. 🎯 **Smart Correction Suggestions** (`/claims/suggest_corrections`)
   - Cross-references 1000+ Georgia EOB codes with payer policies
   - Maps important denial codes (eg: remit codes and remark codes) to detailed explanations
   - Provides actionable correction recommendations for each denial

#### 4. ✍️ **Automated Appeal Generation** (`/claims/generate_appeal`)
   - Input deidentified patient information to LLM to generates fully formatted, persuasive appeal letters.
   - Cites relevant policy language and supporting documentation
   - Customizable templates for different payers and denial types
   - Addresses each denial code with specific corrections


<!-- - **Document intake** – `Claims::DocumentAnalyzer` routes uploads to `Claims::PdfAnalyzer` (pdf-reader/combine_pdf) or `Claims::OcrReader` (rtesseract) for text extraction.
- **Rule mapping** – `DenialRules::Repository` reads from the `denial_reasons` table (populated via `config/EOBList.csv`) and falls back to `config/denial_rules.yml` so payer logic can change without redeploys.
- **Appeal Generating** – `Appeals::AppealGenerator` queries gpt-4o-mini using an openai api key and generates appeal letters for denied claims. It takes in specific information about the case to write a strong appeal letter.
- **Storage targets** – PostgreSQL remains the system of record for claims/denials; ActiveStorage (with S3/GCS/Azure) should store original PDFs and generated appeals once wired up.
- **Async/AI** – Sidekiq is included so heavy OCR, PDF builds, or LLM calls can move to background jobs in future iterations. -->

## HTTP Endpoints

| Endpoint | Purpose | Required params |
| --- | --- | --- |
| `POST /claims/analyze` | Ingest a denied-claim PDF/image and return extracted metadata and denial codes. | `file` (multipart upload) |
| `POST /claims/suggest_corrections` | Map denial/EOB codes (or `[remit_code, remark_code]` tuples like `["CO45","N54"]`) to stored reasons/corrections. | `denial_codes[]` |
| `POST /claims/generate_appeal` | Produce an appeal draft using claim payload + denial reasons. | `claim[...]`, `denial_codes[]`

# Example Requests to Test Specific Endpoints
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
To test from terminal:
** You must have environment variable $OPENAI_API_KEY set for this to work.
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
To test from rails console:  
`rails c`
```

service = Appeals::AppealGenerator.new(
claim: { claim_number: "A123", patient_name: "John Doe", payer_name: "Aetna", service_period: "2025-01-10" },
denial_reasons: ["Missing pre-authorization"]
)
puts service.call[:appeal_letter]
```


## Configuring OCR & Rules

- Install Tesseract locally to unlock `Claims::OcrReader` (`brew install tesseract` on macOS).
- Maintain denial data primarily via the `denial_reasons` table (see next section); `config/denial_rules.yml` remains as a lightweight fallback for quick overrides.
- Swap the appeal template or add new ones under `app/views/appeals/templates`, then pass `template` when calling `/claims/generate_appeal`.

## Denial Reason Database

- Run `bin/rails db:migrate` to create the `denial_reasons` table with columns for EOB code (`code`), payer description, rejection code, group code, parsed reason codes (array), remark code, suggested corrections, and documentation.
- Keep the GA EOB crosswalk (or any payer-provided spreadsheet) in `config/EOBList.csv`. Seed the table via `bin/rails db:seed` or manually import with `bin/rails denial_reasons:import_eob[/absolute/path/to/EOBList.csv]`.
- Each row in the CSV must include headers `EOB CODE, DESCRIPTION, Rejection Code, Group Code, Reason Code, Remark Code`; multiple reason codes in a single cell (e.g., `"A1, 45 N54"`) are automatically split into arrays.
- `Claims::CorrectionSuggester` accepts plain codes (e.g., `"001"`) or ERA-style tuples. It automatically splits remittance codes like `"CO29"` into `group_code: "CO"` and `reason_code: "29"` before querying the database, and also matches on remark codes such as `"N211"`.
- Export the curated DB for auditing/sharing with `bin/rails denial_reasons:export_csv[optional/output.csv]`.
- `Claims::CorrectionSuggester` consumes these records, so the REST API immediately reflects any newly imported or edited codes.

## 🚀 Deployment

The production app is deployed on Heroku.
You can access the live instance here:

👉link: https://clearclaim-coms4152-c1ad14d4491b.herokuapp.com/

The OpenAI API key is securely stored in Heroku environment variables (OPENAI_API_KEY),
so no manual setup is required to test the deployed app.


## Testing

Run RSpec:

```bash
bundle exec rspec
```
Line Coverage: 92.75% (371 / 400)

Run Cucumber:

```bash
bundle exec cucumber
```
Line Coverage: 85.5% (342 / 400)


Cucumber user stories can be found in our features/.feature files.
## User Testing
On the homepage, upload any of the 3 provided sample pdf files which can be found under `spec/fixtures/`.  
Then Analyze Document > Generate Appeal.  
You can then download the appeal letter as a .docx and customize it further.

### Error Handling Tip
If you upload any invalid document without valid information (like the course syllabus that we showed on demo day), ClearClaim will prompt you to upload another document.

### Targeted Denial Logic Tests

- Service and repository behaviour for denial lookups lives under `spec/services`. Run just those specs with:

  ```bash
  bundle exec rspec spec/services/claims/correction_suggester_spec.rb spec/services/denial_rules/repository_spec.rb
  ```

- Controller behaviour (tuple payloads, JSON responses) is covered by `spec/requests/claims_controller_spec.rb`:

  ```bash
  bundle exec rspec spec/requests/claims_controller_spec.rb
  ```

- End-to-end cucumber scenario for ERA tuples is defined in `features/denial_corrections.feature`:

  ```bash
  bundle exec cucumber features/denial_corrections.feature
  ```

These tests assume you have migrated and seeded the database (`bin/rails db:migrate db:seed`) so the denial lookup table exists.
