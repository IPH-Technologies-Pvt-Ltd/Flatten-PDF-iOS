import UIKit
import PDFKit

class ViewController: UIViewController, UIDocumentPickerDelegate {
    
    
    //MARK: IBOutlets
    @IBOutlet weak var flattenPDFLbl: UILabel!
    @IBOutlet weak var makeYourEditorLbl: UILabel!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var sizeLimitLbl: UILabel!
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var flattenButton: UIButton!
    @IBOutlet weak var noSelectLbl: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    

    //MARK: Life Cycle Method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        flattenButton.isHidden = true
        downloadButton.isHidden = true
        uploadButton.layer.cornerRadius = 10
        flattenButton.layer.cornerRadius = 10
        downloadButton.layer.cornerRadius = 10
        progressView.isHidden = true
        
    }
    
    
    //MARK: -Actions
    @IBAction func uploadPDFButtonAction(_ sender: Any) {
        
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf"], in: .import)
          documentPicker.delegate = self
          documentPicker.allowsMultipleSelection = false
          present(documentPicker, animated: true, completion: nil)
       
    }
    
    @IBAction func flattenBtnAction(_ sender: UIButton) {
        
        if pdfView.document == nil {
            showAlert(message: "Please select a PDF first.")
        } else {
            do {
                progressView.isHidden = false
                progressView.progress = 0.0
                
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    
                    self.progressView.progress += 0.25
                    
                    if self.progressView.progress >= 1.0 {
                        timer.invalidate()
                        self.progressView.isHidden = true
                        self.continueFlattenProcess()
                    }
                }
                
            } catch {
                print("Error flattening PDF: \(error)")
            }
        }
    }
    
    func continueFlattenProcess() {
        do {
            let flattenedDocument = try pdfView.document?.flattened()
            pdfView.document = flattenedDocument
            let ducumentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            flattenButton.isHidden = true
            downloadButton.isHidden = false
        } catch {
            print("Error flattening PDF: \(error)")
        }
    }
    
    @IBAction func downloadButtonAction(_ sender: UIButton) {
        
        if pdfView.document == nil {
                showAlert(message: "Please select a PDF first.")
            } else {
                showActionSheet()
            }
    }
    
    
    func showAlert(message: String) {
        
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }
    
    func showActionSheet() {
        
            let alertController = UIAlertController(title: "Choose an action", message: nil, preferredStyle: .actionSheet)
            let saveAction = UIAlertAction(title: "Save PDF", style: .default) { _ in
                self.savePDF()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)

            if let popoverController = alertController.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }

            present(alertController, animated: true, completion: nil)
        
        }
    
    
    func savePDF() {
        
        if let pdfDocument = pdfView.document {
            if let pdfData = pdfDocument.dataRepresentation() {
                let activityViewController = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                self.present(activityViewController, animated: true, completion: nil)
            }
        }
        
    }


    func printPDF() {
        
        guard let flattenedDocument = pdfView.document else {
            return
        }
        let printController = UIPrintInteractionController.shared

        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = "Print Job"

        printController.printInfo = printInfo
        printController.showsPageRange = true
        printController.printingItem = flattenedDocument.dataRepresentation()

        printController.present(animated: true) { (_, isPrinted, error) in
            if isPrinted {
                print("Print job completed successfully.")
            } else if let error = error {
                print("Error printing: \(error.localizedDescription)")
            } else {
                print("Print job canceled.")
            }
        }
        
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
       
        guard let selectedFileURL = urls.first else {
            return
        }
        flattenButton.setTitle("Flatten", for: .normal)
        flattenButton.isHidden = false
        downloadButton.isHidden = true
        noSelectLbl.isHidden = true
        pdfView.document = PDFDocument(url: selectedFileURL)
        
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }
    
    
    func flattenPDFDocument(at url: URL, withDPI dpi: CGFloat = 72) throws -> PDFDocument {
        
        guard let originalDocument = PDFDocument(url: url) else {
            throw NSError(domain: "com.yourapp.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load PDF document."])
        }

        let flattenedDocument = PDFDocument()

        for pageIndex in 0..<originalDocument.pageCount {
            guard let originalPage = originalDocument.page(at: pageIndex) else {
                continue
            }

            let flattenedPageImage = originalPage.image(withDPI: dpi)

            if let flattenedPage = PDFPage(image: flattenedPageImage) {
                flattenedDocument.insert(flattenedPage, at: flattenedDocument.pageCount)
            } else {
                print("Error creating flattened page for index \(pageIndex)")
            }
        }

        return flattenedDocument
    }
    
}


extension PDFPage {
    func image(withDPI dpi: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        let pageRect = bounds(for: .mediaBox)
        let dpiRatio = dpi / 72
        let scaleTransform = CGAffineTransform(scaleX: dpiRatio, y: dpiRatio)
        let imageSize = pageRect.size.applying(scaleTransform)
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        return renderer.image { ctx in
            UIColor(white: 1.0, alpha: 1.0).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
            ctx.cgContext.saveGState()
            ctx.cgContext.translateBy(x: 0, y: imageSize.height)
            ctx.cgContext.scaleBy(x: dpiRatio, y: -dpiRatio)
            draw(with: .mediaBox, to: ctx.cgContext)
            ctx.cgContext.flush()
            ctx.cgContext.restoreGState()
        }
    }
}

extension PDFDocument {
    func flattened(withDPI dpi: CGFloat = 72) throws -> PDFDocument {
        let flattenedDocument = PDFDocument()
        for pageIndex in 0..<pageCount {
            let oldPage = page(at: pageIndex)
            let image = oldPage?.image(withDPI: dpi)
            if (image != nil && image?.cgImage != nil) {
                let flattenedPage = PDFPage(image: image!)
                if (flattenedPage != nil) {
                    flattenedDocument.insert(flattenedPage!, at: flattenedDocument.pageCount)
                }
            } else {
                NSLog("@Cannot convert to image")
            }
        }
        return flattenedDocument
    }
}
