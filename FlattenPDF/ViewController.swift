//
//  ViewController.swift
//  FlattenPDF


import UIKit
import PDFKit
import ZIPFoundation


class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIDocumentPickerDelegate,UICollectionViewDelegateFlowLayout{
    
    
    //MARK: IBOutlets
    @IBOutlet weak var flattenPdfLbl: UILabel!
    @IBOutlet weak var editorLbl: UILabel!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var flattenPdfButton: UIButton!
    @IBOutlet weak var myCollectionView: UICollectionView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var downloadBtn: UIButton!
    
    
    //MARK: variables
    var pdfs:[PDFModel] = []
    
    
    //MARK: Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
                
        myCollectionView.delegate = self
        myCollectionView.dataSource = self
        
        setUpUI()

    }
    
    
    
    //MARK: -Actions
    @IBAction func uploadButtonAction(_ sender: UIButton) {
        
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf"], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true, completion: nil)
    
    }
    
    @IBAction func downloadButtonAction(_ sender: UIButton) {
        
        if pdfs.isEmpty {
            showAlert(message: "Please select a PDF first.")
            return
        }
    
        let tempDirectory = FileManager.default.temporaryDirectory
        let zipFileName = "pdfs.zip"
        let zipFilePath = tempDirectory.appendingPathComponent(zipFileName)
        let fileManager = FileManager.default
                
        do {
        
            if fileManager.fileExists(atPath: zipFilePath.path) {
                try fileManager.removeItem(atPath: zipFilePath.path)
            }
            
            let zipArchive = try Archive(url: zipFilePath, accessMode: .create)
            
            for (index, pdf) in pdfs.enumerated() {
                let pdfData = pdf.pdfDoc.dataRepresentation()
                try zipArchive.addEntry(with: "pdf\(index + 1).pdf", type: .file, uncompressedSize: UInt32(pdfData!.count), provider: { position, size -> Data in
                    let range = Range(uncheckedBounds: (position, position + size))
                    return pdfData!.subdata(in: range)
                })
            }
    
            let activityViewController = UIActivityViewController(activityItems: [zipFilePath], applicationActivities: nil)
            
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = sender
                popoverController.sourceRect = sender.bounds
            }
            present(activityViewController, animated: true, completion: nil)
        } catch {
            showAlert(message: "Error creating zip file: \(error.localizedDescription)")
        }
    }
    
    @IBAction func flattenButtonAction(_ sender: UIButton) {
        
        progressView.isHidden = false
           progressView.progress = 0.0

           Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
               self.progressView.progress += 0.25

               if self.progressView.progress >= 1.0 {
                   timer.invalidate()
                   self.progressView.isHidden = true
                   self.downloadBtn.isHidden = false
               }
           }

           do {
               for index in pdfs.indices {

                   let pdfDocument  = pdfs[index].pdfDoc
                   if let pdfData = pdfDocument.dataRepresentation() {
                       let fileSize = pdfData.count
                       let fileSizeString = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
                       pdfs[index].pdfDoc = try pdfDocument.flattened()
                       pdfs[index].pdfSize = fileSizeString
                   }

               }
             
               myCollectionView.reloadData()
           }
           catch {
               print("Error flattening PDF: \(error)")
           }

           flattenPdfButton.isHidden = true
           downloadBtn.isHidden = true
    }
    
    
    //MARK: -setUpUI
    func setUpUI() {
        
        progressView.isHidden = true
        flattenPdfButton.isHidden = true
        flattenPdfButton.layer.cornerRadius = 10
        downloadBtn.isHidden = true
        downloadBtn.layer.cornerRadius = 10
        
    }
    
    
    func showAlert(message: String) {
        
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }
    
    func savePDF(pdfDocument: PDFDocument) {
       
        guard let pdfData = pdfDocument.dataRepresentation() else {
            showAlert(message: "Error getting PDF data.")
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        present(activityViewController, animated: true, completion: nil)
         
    }
    
    
    func saveFlattenedPDF(document: PDFDocument?) {
        
        if let flattenedDocument = document {
            if let pdfData = flattenedDocument.dataRepresentation() {
                let fileSize = pdfData.count
                let fileSizeString = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
                print("Flattened PDF Size: \(fileSizeString)")
            }
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pdfs.compactMap { $0 }.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = myCollectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MyCollectionViewCell
        
        cell.loadPDFDocument(pdfs[indexPath.item])
        
        
        if pdfs.count == 1 {
            cell.leadingConstraint.constant = 115
        } else {
            cell.leadingConstraint.constant = 10
        }
        
       
        cell.layoutIfNeeded()
        myCollectionView.reloadData()
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if pdfs.count == 1 {
          
            let cellWidth = collectionView.frame.width - 10
            let cellHeight: CGFloat = 230
            let xOffset = (myCollectionView.frame.width - cellWidth) / 2.0
            return CGSize(width: cellWidth, height: cellHeight)
        } else {
            
            let cellWidth = collectionView.frame.width - 220
            let cellHeight: CGFloat = 230
           
            return CGSize(width: cellWidth, height: cellHeight)
        }
        
    }
    
  
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
      
        pdfs = []
        for selectedFileURL in urls{
            do {
                let pdfDocument = try PDFDocument(url: selectedFileURL)
                if let pdfData = pdfDocument?.dataRepresentation() {
                    let fileSize = pdfData.count
                    let fileSizeString = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
                    pdfs.append(PDFModel(pdfDoc: pdfDocument!, pdfSize: fileSizeString))
                    flattenPdfButton.isHidden = false
                    downloadBtn.isHidden = true
                }
            } catch {
                showAlert(message: "Error loading PDF: \(error.localizedDescription)")
            }
        }
        
        myCollectionView.reloadData()
        
        
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
