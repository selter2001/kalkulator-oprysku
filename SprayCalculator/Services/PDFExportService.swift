import SwiftUI

struct PDFExportService {
    @MainActor
    static func generatePDF(
        for calculation: SprayCalculation,
        localization: LocalizationManager
    ) -> URL {
        let content = PDFContentView(
            calculation: calculation,
            localization: localization
        )
        .frame(width: 595) // A4 width in points (210mm)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2.0 // Retina quality

        let url = URL.documentsDirectory.appending(path: "KalkulatorOprysku.pdf")

        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }

        return url
    }
}
