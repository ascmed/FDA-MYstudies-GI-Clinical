import Foundation
import Combine
import PDFKit

// MARK: - Consent View Model
class ConsentViewModel: ObservableObject {
    @Published var consentForm: ConsentForm?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    @Published var consentStatus: ConsentStatus?

    private let apiService = APIService.shared
    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Fetch Consent Form
    func fetchConsentForm(for studyId: String) {
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                // Check cache first
                if let cachedForm = try? storageService.getConsentForm(for: studyId) {
                    self.consentForm = cachedForm
                    self.isLoading = false
                    return
                }

                // Fetch from API
                let form = try await apiService.getConsentFormAsync(forStudy: studyId)
                self.consentForm = form

                // Cache locally
                try storageService.saveConsentForm(form)

                isLoading = false
            } catch {
                errorMessage = "Failed to load consent form: \(error.localizedDescription)"
                isLoading = false
                Logger.error("Failed to load consent form: \(error)")
            }
        }
    }

    // MARK: - Submit Consent (Combine-based)
    func submitConsent(signature: ConsentSignature) {
        isSaving = true
        errorMessage = nil

        let request = ConsentRequest(
            consentFormId: signature.consentFormId,
            signatureName: signature.signatureName,
            signatureImage: signature.signatureImage,
            consentedAt: signature.signedAt,
            ipAddress: signature.ipAddress
        )

        apiService.submitConsent(request)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.isSaving = false
                    Logger.error("Failed to submit consent: \(error)")
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                self?.isSaving = false
                Logger.log("Consent submitted successfully: \(response.consentId)")

                // Save signature locally
                try? self?.storageService.saveConsentSignature(signature)
            }
            .store(in: &cancellables)
    }

    // MARK: - Submit Consent (Async/Await)
    func submitConsentAsync(signature: ConsentSignature) async throws {
        isSaving = true
        errorMessage = nil

        defer { isSaving = false }

        let request = ConsentRequest(
            consentFormId: signature.consentFormId,
            signatureName: signature.signatureName,
            signatureImage: signature.signatureImage,
            consentedAt: signature.signedAt,
            ipAddress: signature.ipAddress
        )

        do {
            let response = try await apiService.submitConsentAsync(request)
            Logger.log("Consent submitted successfully: \(response.consentId)")

            // Save signature locally
            try storageService.saveConsentSignature(signature)
        } catch {
            errorMessage = error.localizedDescription
            Logger.error("Failed to submit consent: \(error)")
            throw error
        }
    }

    // MARK: - Get Consent Status
    func getConsentStatus(for studyId: String) async throws -> ConsentStatus {
        do {
            let status = try await apiService.getConsentStatus(for: studyId)
            await MainActor.run {
                self.consentStatus = status
            }
            return status
        } catch {
            Logger.error("Failed to get consent status: \(error)")
            throw error
        }
    }

    // MARK: - Generate PDF
    func generateConsentPDF(from consentForm: ConsentForm) -> PDFDocument? {
        let pdfDocument = PDFDocument()

        // Create PDF page from HTML content
        let htmlString = createHTMLFromConsentForm(consentForm)

        guard let printFormatter = UIMarkupTextPrintFormatter(markupText: htmlString) else {
            return nil
        }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        do {
            let data = renderer.pdfData { context in
                context.beginPage()
                printFormatter.drawInRect(
                    CGRect(x: 36, y: 36, width: 540, height: 720),
                    forPageAtIndex: 0
                )
            }

            return PDFDocument(data: data)
        } catch {
            Logger.error("Failed to generate PDF: \(error)")
            return nil
        }
    }

    // MARK: - Create HTML from Consent Form
    private func createHTMLFromConsentForm(_ form: ConsentForm) -> String {
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body { font-family: Arial, sans-serif; font-size: 12pt; line-height: 1.5; }
                h1 { font-size: 18pt; font-weight: bold; margin-bottom: 10pt; }
                h2 { font-size: 14pt; font-weight: bold; margin-top: 12pt; margin-bottom: 6pt; }
                p { margin-bottom: 10pt; }
                .header { text-align: center; margin-bottom: 20pt; }
                .footer { margin-top: 20pt; padding-top: 10pt; border-top: 1pt solid black; }
                .section { margin-bottom: 15pt; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>\(form.title)</h1>
                <p>Version \(form.version)</p>
            </div>
        """

        // Add pages
        if let pages = form.pages, !pages.isEmpty {
            for page in pages.sorted(by: { $0.displayOrder < $1.displayOrder }) {
                html += "<div class='section'>"
                if let pageTitle = page.title {
                    html += "<h2>\(pageTitle)</h2>"
                }
                html += "<p>\(page.content)</p>"
                html += "</div>"
            }
        } else {
            html += "<div class='section'><p>\(form.content)</p></div>"
        }

        // Add footer
        html += """
        <div class='footer'>
            <p><strong>Date Generated:</strong> \(Date().formatted(date: .abbreviated, time: .omitted))</p>
            <p>This is an electronic copy of the informed consent form.</p>
        </div>
        </body>
        </html>
        """

        return html
    }

    // MARK: - Save Consent PDF
    func saveConsentPDF(_ pdf: PDFDocument, for consentFormId: String) throws {
        guard let pdfData = pdf.dataRepresentation() else {
            throw ConsentError.pdfGenerationFailed
        }

        // Save to documents directory
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsDirectory.appendingPathComponent("consent_\(consentFormId).pdf")

        try pdfData.write(to: pdfURL)
        Logger.log("Consent PDF saved to: \(pdfURL.path)")
    }

    // MARK: - Load Saved Consent PDF
    func loadConsentPDF(for consentFormId: String) -> PDFDocument? {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsDirectory.appendingPathComponent("consent_\(consentFormId).pdf")

        guard fileManager.fileExists(atPath: pdfURL.path) else {
            return nil
        }

        return PDFDocument(url: pdfURL)
    }

    // MARK: - Get Consent History
    func getConsentHistory() -> [ConsentSignature] {
        do {
            return try storageService.getAllConsentSignatures()
        } catch {
            Logger.error("Failed to get consent history: \(error)")
            return []
        }
    }

    // MARK: - Revoke Consent
    func revokeConsent(for studyId: String) async throws {
        do {
            try await apiService.revokeConsent(for: studyId)
            Logger.log("Consent revoked for study: \(studyId)")
        } catch {
            Logger.error("Failed to revoke consent: \(error)")
            throw error
        }
    }

    // MARK: - Check Consent Validity
    func isConsentValid(for studyId: String) -> Bool {
        if let status = consentStatus {
            return status.isValid && status.studyId == studyId
        }
        return false
    }

    // MARK: - Download Consent PDF
    func downloadConsentPDF(for consentFormId: String) async throws -> URL? {
        do {
            let pdfURL = try await apiService.downloadConsentPDF(for: consentFormId)
            return pdfURL
        } catch {
            Logger.error("Failed to download consent PDF: \(error)")
            throw error
        }
    }

    // MARK: - Email Consent Copy
    func emailConsentCopy(_ pdf: PDFDocument, to email: String) throws {
        guard let pdfData = pdf.dataRepresentation() else {
            throw ConsentError.pdfGenerationFailed
        }

        // This would typically be handled by backend
        // Store reference for later use
        try storageService.saveConsentForEmail(pdfData, recipient: email)
        Logger.log("Consent queued for email to: \(email)")
    }
}

// MARK: - Consent Error
enum ConsentError: LocalizedError {
    case formNotFound
    case pdfGenerationFailed
    case submissionFailed
    case invalidSignature
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .formNotFound:
            return "Consent form not found"
        case .pdfGenerationFailed:
            return "Failed to generate PDF document"
        case .submissionFailed:
            return "Failed to submit consent"
        case .invalidSignature:
            return "Invalid signature information"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
