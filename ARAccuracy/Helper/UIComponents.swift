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

    let button = UIButton(type: .custom)

    init(imageName: String, tintColor: UIColor = .white) {
        super.init(frame: .zero)
        setupView(imageName: imageName, tintColor: tintColor)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView(imageName: String, tintColor: UIColor) {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 24
        layer.masksToBounds = true

        // Dark blur effect
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 24
        blurView.layer.masksToBounds = true
        addSubview(blurView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // Button setup
        let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = tintColor
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}



