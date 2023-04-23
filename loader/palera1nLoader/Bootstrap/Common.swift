//
//  Common.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/10/23.
//

import Foundation
import LaunchServicesBridge
import UIKit

struct envInfo {
    static var isRootful: Bool = false
    static var isSimulator: Bool = false
    static var installPrefix: String = "unset"
    static var rebootAfter: Bool = true
    static var hasHelper: Bool = false
    static var helperPath: String = "unset"
    static var envType: Int = -1
    static var systemVersion: String = "unset"
    static var systemArch: String = "unset"
    static var isInstalled: Bool = false
    static var hasForceReverted: Bool = false
    static var sileoInstalled: Bool = false
    static var zebraInstalled: Bool = false
    static var hasChecked: Bool = false
}

// will be removed
let global = (UIApplication.shared.connectedScenes.filter { $0.activationState == .foregroundActive }
    .first(where: { $0 is UIWindowScene }).flatMap({ $0 as? UIWindowScene })?.windows.first(where: \.isKeyWindow)?.rootViewController!)!

func local(_ str: String.LocalizationValue) -> String {
    return String(localized: str)
}

func helperCmd(_ args: [String]) -> Int {
    return spawn(command: envInfo.helperPath, args: args, root: true)
}

func fileExists(_ path: String) -> Bool {
    return FileManager.default.fileExists(atPath: path)
}

func docsFile(file: String) -> String {
   return "\(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(file).path)"
}

func whichAlert(title: String, message: String? = nil) -> UIAlertController {
    if UIDevice.current.userInterfaceIdiom == .pad {
        return UIAlertController(title: title, message: message, preferredStyle: .alert)
    }
    return UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
}

func openApp(_ bundle: String) -> Bool {
    return LSApplicationWorkspace.default().openApplication(withBundleID: bundle)
}

func deleteFile(file: String) -> Void {
   let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
   let fileURL = documentsURL.appendingPathComponent(file)
   try? FileManager.default.removeItem(at: fileURL)
}

// will be removed
func errAlert(title: String, message: String) {
    DispatchQueue.main.async {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: local("CLOSE"), style: .default) { _ in
            bootstrap().cleanUp()
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { exit(0) }
        })
        
        if (global.presentedViewController != nil) {
            global.presentedViewController!.dismiss(animated: true) {
                global.present(alertController, animated: true, completion: nil)
            }
        } else {
            global.present(alertController, animated: true, completion: nil)
        }
    }
}
// image mods
func applySymbolModifications(to cell: UITableViewCell, with symbolName: String, backgroundColor: UIColor) {
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
    let symbolImage = UIImage(systemName: symbolName, withConfiguration: symbolConfig)?
        .withTintColor(.white, renderingMode: .alwaysOriginal)
    let symbolSize = symbolImage?.size ?? .zero
    let imageSize = CGSize(width: 30, height: 30)
    let scale = min((imageSize.width - 6) / symbolSize.width, (imageSize.height - 6) / symbolSize.height)
    let adjustedSymbolSize = CGSize(width: symbolSize.width * scale, height: symbolSize.height * scale)
    let coloredBackgroundImage = UIGraphicsImageRenderer(size: imageSize).image { context in
        backgroundColor.setFill()
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: imageSize), cornerRadius: 7).fill()
    }
    let mergedImage = UIGraphicsImageRenderer(size: imageSize).image { context in
        coloredBackgroundImage.draw(in: CGRect(origin: .zero, size: imageSize))
        symbolImage?.draw(in: CGRect(x: (imageSize.width - adjustedSymbolSize.width) / 2, y: (imageSize.height - adjustedSymbolSize.height) / 2, width: adjustedSymbolSize.width, height: adjustedSymbolSize.height))
    }
    cell.imageView?.image = mergedImage
    cell.imageView?.layer.cornerRadius = 7
    cell.imageView?.clipsToBounds = true
    cell.imageView?.layer.borderWidth = 1
    cell.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
}

func applyImageModifications(to cell: UITableViewCell, with originalImage: UIImage) {
    let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { context in
        originalImage.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
    }
    cell.imageView?.image = resizedImage
    cell.imageView?.layer.cornerRadius = 7
    cell.imageView?.clipsToBounds = true
    cell.imageView?.layer.borderWidth = 1
    cell.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
}
extension UIAlertController {
    static func warning(title: String, message: String, destructiveBtnTitle: String?, destructiveHandler: (() -> Void)?) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let destructiveTitle = destructiveBtnTitle, let handler = destructiveHandler {
            alertController.addAction(UIAlertAction(title: destructiveTitle, style: .destructive) { _ in handler() })
        }
        alertController.addAction(UIAlertAction(title: local("CANCEL"), style: .cancel) { _ in return })
        return alertController
    }
    
    static func error(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: local("CLOSE"), style: .default) { _ in
            bootstrap().cleanUp()
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { exit(0) }
        })
        return alertController
    }
    
    static func downloading(_ msg: String.LocalizationValue) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: local(msg), preferredStyle: .alert)
        let constraintHeight = NSLayoutConstraint(item: alertController.view!, attribute: NSLayoutConstraint.Attribute.height,
                                                  relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute:
                                                    NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 75)
        alertController.view.addConstraint(constraintHeight)
        progressDownload.setProgress(0.0/1.0, animated: true)
        progressDownload.frame = CGRect(x: 25, y: 55, width: 220, height: 0)
        alertController.view.addSubview(progressDownload)
        return alertController
    }
    
    static func spinnerAlert(_ msg: String.LocalizationValue) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: local(msg), preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        alertController.view.addSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        return alertController
    }
}