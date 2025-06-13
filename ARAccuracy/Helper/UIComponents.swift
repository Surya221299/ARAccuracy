//
//  UIComponents.swift
//  ARAccuracy
//
//  Created by Surya on 09/06/25.
//

import UIKit

class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }
}

class ARPlaceButton: UIButton {

    private let innerCircle = UIView()
    private let iconImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = .black
        layer.cornerRadius = 20
        layer.masksToBounds = true

        if #available(iOS 13.0, *) {
            layer.cornerCurve = .continuous
        }

        // Inner white circle
        innerCircle.backgroundColor = .white
        innerCircle.layer.cornerRadius = 27.5
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.isUserInteractionEnabled = false
        addSubview(innerCircle)

        // Icon inside the circle
        iconImageView.image = UIImage(named: "place")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.isUserInteractionEnabled = false
        innerCircle.addSubview(iconImageView)

        // Constraints
        NSLayoutConstraint.activate([
            innerCircle.centerXAnchor.constraint(equalTo: centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 55),
            innerCircle.heightAnchor.constraint(equalToConstant: 55),

            iconImageView.centerXAnchor.constraint(equalTo: innerCircle.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: innerCircle.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30)
        ])

        // Initial state
        isEnabled = false
        alpha = 0.5
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        alpha = enabled ? 1.0 : 0.3
    }
}

class CircularGlassButton: UIView {
    let button = UIButton()
    private let backgroundView = UIView()

    init(imageName: String, tintColor: UIColor) {
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        // Circular background view
        backgroundView.backgroundColor = .systemBackground.withAlphaComponent(0.8) // Will override later
        backgroundView.layer.cornerRadius = 24
        backgroundView.clipsToBounds = true
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)

        // Setup button with image
        let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = tintColor
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 48),
            heightAnchor.constraint(equalToConstant: 48),

            backgroundView.widthAnchor.constraint(equalToConstant: 48),
            backgroundView.heightAnchor.constraint(equalToConstant: 48),
            backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),

            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 48),
            button.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setBackgroundColor(_ color: UIColor) {
        backgroundView.backgroundColor = color
    }
}


extension UIImage {
    static func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: Double = 0

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
            }

            let delaySeconds = UIImage.delayForImageAtIndex(i, source: source)
            duration += delaySeconds
        }

        return UIImage.animatedImage(with: images, duration: duration)
    }

    static func delayForImageAtIndex(_ index: Int, source: CGImageSource) -> Double {
        var delay = 0.1
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        if let gifProperties = (cfProperties as NSDictionary?)?[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
           let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
            delay = unclampedDelay.doubleValue
        }

        return delay < 0.01 ? 0.1 : delay
    }
}


extension UIApplication {
    func topMostViewController(base: UIViewController? = UIApplication.shared.windows
        .first(where: { $0.isKeyWindow })?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            return topMostViewController(base: tab.selectedViewController)
        }
        
        if let presented = base?.presentedViewController {
            return topMostViewController(base: presented)
        }
        
        return base
    }
}
