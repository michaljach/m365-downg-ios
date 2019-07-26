//
//  FlashViewController.swift
//  m365-info-ios
//
//  Created by Michał Jach on 22/07/2019.
//  Copyright © 2019 Michał Jach. All rights reserved.
//

import UIKit
import MobileCoreServices
import SSZipArchive

class FlashViewController: UIViewController {
    var m365info: M365Info?
    var destPath = ""
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var textView: UITextView!
    
    @IBAction func flashTapped(_ sender: Any) {
        let types: [String] = [kUTTypeData as String]
        let documentPicker = UIDocumentPickerViewController(documentTypes: types, in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        m365info?.progressDelegate = self
    }
    
    func checksum(checksum: Int, data: Data) -> Int {
        var temp = Int(checksum)
        for elem in data {
            temp += Int(elem)
        }
        
        return temp & 0xFFFFFFFF
    }
    
    func unzip(archive: String) {
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDir = paths[0]
        let zipPath =  documentsDir.appendingFormat("/bins") // My folder name in document directory
        destPath = zipPath.appendingFormat("/firms")
        
        let fileManager = FileManager.default
        
        let success = fileManager.fileExists(atPath: destPath) as Bool
        
        if success == false {
            
            do {
                
                try! fileManager.createDirectory(atPath: destPath, withIntermediateDirectories: true, attributes: nil)
            }
        }
        
        SSZipArchive.unzipFile(atPath: archive, toDestination: destPath, delegate: self)
    }

}

extension FlashViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        unzip(archive: urls.first!.relativePath)
    }
}

extension FlashViewController: M365ProgressDelegate {
    func didChangeProgress(progress: Float) {
        if progress == 1.0 {
            textView.text.append("\nDONE!")
            do {
                try FileManager.default.removeItem(atPath: destPath)
            } catch {
                
            }
        } else {
            textView.text.append("\nFlashing... " + String(progress))
        }
        let bottom = NSMakeRange(textView.text.count - 1, 1)
        textView.scrollRangeToVisible(bottom)
        progressBar.setProgress(progress, animated: true)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension FlashViewController: SSZipArchiveDelegate {
    func zipArchiveDidUnzipFile(at fileIndex: Int, totalFiles: Int, archivePath: String, unzippedFilePath: String) {
        print(unzippedFilePath)
        if unzippedFilePath.contains("FIRM.bin") && !unzippedFilePath.contains("FIRM.bin.enc") {
            do {
                let data = try Data.init(contentsOf: URL(fileURLWithPath: unzippedFilePath))
                let byteArray: [UInt8] = [UInt8](data)
                let chunked = byteArray.chunked(into: 128)
                var checksum = 0
                var page = 0
                
                m365info?.buffer.append((m365info?.createPacket(address: 0x20, cmd: 0x03, arg: 0x70, payload: [0x01, 0x00]))!) // Locking
                m365info?.buffer.append((m365info?.createPacket(address: 0x20, cmd: 0x07, arg: 0x00, payload: [UInt8(byteArray.count & 0x00ff), UInt8(byteArray.count >> 8), 0x00, 0x00]))!) // Starting update
                
                for chunk in chunked {
                    let packet = m365info?.createPacket(address: 0x20, cmd: 0x08, arg: UInt8(page), payload: chunk)
                    let chunkedByteArray: [UInt8] = [UInt8](packet!)
                    for miniChunk in chunkedByteArray.chunked(into: 20) {
                        m365info?.buffer.append(Data(miniChunk))
                    }
                    checksum = self.checksum(checksum: checksum.littleEndian, data: Data(chunk))
                    page += 1
                }
                
                let finalChecksum = UInt32(checksum ^ 0xFFFFFFFF)
                
                var bigEndian = finalChecksum.bigEndian
                let count = MemoryLayout<UInt32>.size
                let bytePtr = withUnsafePointer(to: &bigEndian) {
                    $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                        UnsafeBufferPointer(start: $0, count: count)
                    }
                }
                let checksumByteArray: [UInt8] = Array(bytePtr).reversed()
                
                m365info?.buffer.append((m365info?.createPacket(address: 0x20, cmd: 0x09, arg: 0x00, payload: checksumByteArray))!) // Finalizing
                m365info?.buffer.append((m365info?.createPacket(address: 0x20, cmd: 0x0a, arg: 0x00, payload: []))!) // Finalizing
                
                m365info?.count = (m365info?.buffer.count)!
                m365info?.flash()
            } catch {
                print("ERROR")
            }
        }
    }
}
