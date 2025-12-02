document.addEventListener('DOMContentLoaded', function() {
  const uploadArea = document.getElementById('upload-area');
  const pdfInput = document.getElementById('pdf-input');
  const fileSelected = document.getElementById('file-selected');
  const previewIframe = document.getElementById('pdf-preview-iframe');
  const submitBtn = document.getElementById('submit-btn');
  const fileName = document.getElementById('file-name');
  const fileSize = document.getElementById('file-size');
  const removeFile = document.getElementById('remove-file');
  const uploadForm = document.getElementById('upload-form');
  const resultsSection = document.getElementById('results-section');
  const resultsContent = document.getElementById('results-content');
  const errorSection = document.getElementById('error-section');
  const errorContent = document.getElementById('error-content');
  const resultsSubtitle = document.querySelector('.results-subtitle');
  const btnText = document.getElementById('btn-text');
  const btnLoading = document.getElementById('btn-loading');
  const actionButtons = document.getElementById('action-buttons');
  const generateBtn = document.getElementById('generate-appeal-btn');
  const analyzeAnotherBtn = document.getElementById('analyze-another-btn');
  
  window.currentClaimData = null;
  
  // File upload handlers
  uploadArea.addEventListener('click', () => pdfInput.click());
  pdfInput.addEventListener('change', handleFile);
  
  // Drag and drop
  uploadArea.addEventListener('dragover', (e) => {
    e.preventDefault();
    uploadArea.classList.add('dragging');
  });
  
  uploadArea.addEventListener('dragleave', () => {
    uploadArea.classList.remove('dragging');
  });
  
  uploadArea.addEventListener('drop', (e) => {
    e.preventDefault();
    uploadArea.classList.remove('dragging');
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      const file = files[0];
      if (file.type === 'application/pdf') {
        pdfInput.files = files;
        handleFile();
      } else {
        alert('Please upload a PDF file');
      }
    }
  });
  
  function handleFile() {
    const file = pdfInput.files[0];
    if (file && file.type === 'application/pdf') {
      fileName.textContent = file.name;
      fileSize.textContent = formatBytes(file.size);
      uploadArea.style.display = 'none';
      fileSelected.style.display = 'block';
      submitBtn.disabled = false;
      
      // Show PDF preview using a data URL so Chrome/Safari render inline
      const reader = new FileReader();
      reader.onload = (event) => {
        previewIframe.src = event.target.result;
      };
      reader.readAsDataURL(file);
    } else {
      alert('Please select a valid PDF file');
      pdfInput.value = '';
    }
  }
  
  removeFile.addEventListener('click', () => {
    pdfInput.value = '';
    fileSelected.style.display = 'none';
    uploadArea.style.display = 'flex';
    submitBtn.disabled = true;
    resultsSection.style.display = 'none';
    errorSection.style.display = 'none';
    previewIframe.removeAttribute('src');
  });
  
  // Form submission
  uploadForm.addEventListener('submit', async (e) => {

    e.preventDefault();
    
    const file = pdfInput.files[0];
    if (!file) {
      alert('Please select a file');
      return;
    }
    
    const formData = new FormData();
    formData.append('file', file);
    
    submitBtn.disabled = true;
    btnText.style.display = 'none';
    btnLoading.style.display = 'inline-flex';
    resultsSection.style.display = 'none';
    errorSection.style.display = 'none';
    
    try {
      const response = await fetch('/claims/analyze', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="authenticity_token"]').value
        }
      });
      
      const data = await response.json();
      
      if (response.ok && data.claim) {
        window.currentClaimData = data.claim;
        displayResults(data.claim);
      } else {
        throw new Error(data.error || 'Failed to analyze document');
      }
    } catch (error) {
      console.error('Error:', error);
      displayError(error.message || 'Failed to analyze document. Please ensure it\'s a valid medical claim PDF.');
    } finally {
      submitBtn.disabled = false;
      btnText.style.display = 'inline';
      btnLoading.style.display = 'none';
    }
  });
  
  function displayResults(claim) {
    let html = '';
    
    const fields = [
      { key: 'claim_number', label: 'Claim Number', icon: '📋' },
      { key: 'patient_name', label: 'Patient Name', icon: '👤' },
      { key: 'payer_name', label: 'Insurance Payer', icon: '🏥' },
      { key: 'service_period', label: 'Service Period', icon: '📅' },
      { key: 'submitter_name', label: 'Provider/Submitter', icon: '👨‍⚕️' }
    ];
    const parsedCodes = extractDenialCodes(claim);
    
    let hasData = false;
    fields.forEach(field => {
      if (claim[field.key]) {
        hasData = true;
        html += `
          <div class="result-card">
            <div class="result-icon">${field.icon}</div>
            <div class="result-label">${field.label}</div>
            <div class="result-value">${claim[field.key]}</div>
          </div>
        `;
      }
    });
    
    if (parsedCodes.length) {
      hasData = true;
      html += `
        <div class="result-card">
          <div class="result-icon">🔖</div>
          <div class="result-label">Parsed Codes</div>
          <div class="result-value">${parsedCodes.join(', ')}</div>
        </div>
      `;
    }
    
    const hasAllBannerFields = fields.every((field) => Boolean(claim[field.key]));
    const hasCodes = parsedCodes.length > 0;
    const hasCompleteBanner = hasAllBannerFields && hasCodes;

    if (!hasData) {
      html = '<div class="no-data">No claim data could be extracted. Please ensure the PDF contains a valid medical claim.</div>';
      actionButtons.style.display = 'flex';
      if (generateBtn) generateBtn.style.display = 'none';
      if (analyzeAnotherBtn) analyzeAnotherBtn.style.display = 'inline-flex';
      if (generateBtn) generateBtn.disabled = true;
      if (resultsSubtitle) resultsSubtitle.textContent = 'Missing required claim details';
    } else if (!hasCompleteBanner) {
      html += '<div class="no-data">We could not extract all required claim details. Please upload a complete medical claim PDF to generate an appeal letter.</div>';
      actionButtons.style.display = 'flex';
      if (generateBtn) generateBtn.style.display = 'none';
      if (analyzeAnotherBtn) analyzeAnotherBtn.style.display = 'inline-flex';
      if (generateBtn) generateBtn.disabled = true;
      if (resultsSubtitle) resultsSubtitle.textContent = 'Missing required claim details';
    } else {
      actionButtons.style.display = 'flex';
      if (generateBtn) generateBtn.style.display = 'inline-flex';
      if (analyzeAnotherBtn) analyzeAnotherBtn.style.display = 'inline-flex';
      if (generateBtn) generateBtn.disabled = false;
      if (resultsSubtitle) resultsSubtitle.textContent = 'Document successfully parsed and analyzed';
    }
    
    resultsContent.innerHTML = html;
    resultsSection.style.display = 'block';
    resultsSection.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }
  
  function displayError(message) {
    errorContent.innerHTML = `
      <div class="error-message">
        <strong>⚠️ Error:</strong> ${message}
      </div>
      <button class="btn-secondary" onclick="resetForm()">Try Another File</button>
    `;
    errorSection.style.display = 'block';
    errorSection.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }
  
  function resetForm() {
    // Return UI to initial upload state without leaving the page.
    pdfInput.value = '';
    fileSelected.style.display = 'none';
    uploadArea.style.display = 'flex';
    submitBtn.disabled = true;
    resultsSection.style.display = 'none';
    errorSection.style.display = 'none';
    actionButtons.style.display = 'none';
    if (generateBtn) generateBtn.style.display = 'inline-flex';
    if (analyzeAnotherBtn) analyzeAnotherBtn.style.display = 'inline-flex';
    if (generateBtn) generateBtn.disabled = true;
    if (resultsSubtitle) resultsSubtitle.textContent = 'Document successfully parsed and analyzed';
    resultsContent.innerHTML = '';
    currentClaimData = null;
    previewIframe.removeAttribute('src');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function extractDenialCodes(claim) {
    if (!claim) return [];

    const legacy = Array.isArray(claim.denial_codes) ? claim.denial_codes : [];
    const fromLineItems = Array.isArray(claim.line_items)
      ? claim.line_items.flatMap((item) => [
          ...(item.remit_codes || []),
          ...(item.remark_codes || [])
        ])
      : [];

    return [...new Set([...legacy, ...fromLineItems].map((code) => code?.toString().trim()).filter(Boolean))];
  }
  
  async function generateAppeal() {
    if (!generateBtn || generateBtn.disabled) return;

    generateBtn.disabled = true;
    generateBtn.textContent = 'Generating...';
    const denialCodes = extractDenialCodes(currentClaimData);

    try {
      const response = await fetch('/claims/generate_appeal', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="authenticity_token"]').value
        },
        body: JSON.stringify({
          claim: currentClaimData,
          denial_codes: denialCodes
        })
      });

      // Read body once safely
      const text = await response.text();
      let data;
      try {
        data = JSON.parse(text);
      } catch {
        throw new Error('Server returned non-JSON response: ' + text);
      }

      if (response.ok && data.appeal_letter) {
        // Option 1: short letters — pass via URL
        const encoded = encodeURIComponent(data.appeal_letter);
        window.location.href = `/appeal_letter?content=${encoded}`;

      } else {
        throw new Error(data.error || 'Failed to generate appeal letter.');
      }
    } catch (error) {
      console.error('Error generating appeal:', error);
      alert('Something went wrong: ' + error.message);
    } finally {
      generateBtn.disabled = false;
      generateBtn.textContent = 'Generate Appeal Letter';
    }
  }
  if (generateBtn) {
    generateBtn.addEventListener('click', generateAppeal);
  }
  if (analyzeAnotherBtn) {
    analyzeAnotherBtn.addEventListener('click', resetForm);
  }
    
    function formatBytes(bytes) {
      if (bytes === 0) return '0 Bytes';
      const k = 1024;
      const sizes = ['Bytes', 'KB', 'MB'];
      const i = Math.floor(Math.log(bytes) / Math.log(k));
      return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
    }
});


window.resetForm = function() {
  resetForm();
};
