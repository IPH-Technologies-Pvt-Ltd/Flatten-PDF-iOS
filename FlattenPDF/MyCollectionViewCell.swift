//
//  MyCollectionViewCell.swift
//  FlattenPDF

import UIKit
import PDFKit

class MyCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    
    
    func loadPDFDocument(_ pdfModel: PDFModel) {
           
            if let pdfView = self.pdfView {
                pdfView.document = pdfModel.pdfDoc
                myLabel.text = "Size: \(pdfModel.pdfSize)"
                pdfView.autoScales = true
            } else {
                print("PDFView is nil")
            }
        }
}
