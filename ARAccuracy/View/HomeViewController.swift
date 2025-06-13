//
//  HomeViewController.swift
//  ARAccuracy
//
//  Created by Surya on 09/06/25.
//

import UIKit
import SwiftUI

class HomeViewController: UIViewController {

    private let clippingContainer = UIView()
    private let mapViewContainer = UIView()
    private let overlayContainer = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContainers()
        setupMapView()
        setupLocations()
        applyTiltTransform()
    }

    private func setupContainers() {
        [clippingContainer, mapViewContainer, overlayContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        clippingContainer.clipsToBounds = true
        view.addSubview(clippingContainer)
        clippingContainer.pinToEdges(of: view)

        clippingContainer.addSubview(mapViewContainer)
        NSLayoutConstraint.activate([
            mapViewContainer.topAnchor.constraint(equalTo: clippingContainer.topAnchor, constant: -300),
            mapViewContainer.bottomAnchor.constraint(equalTo: clippingContainer.bottomAnchor, constant: 200),
            mapViewContainer.leadingAnchor.constraint(equalTo: clippingContainer.leadingAnchor),
            mapViewContainer.trailingAnchor.constraint(equalTo: clippingContainer.trailingAnchor)
        ])

        view.addSubview(overlayContainer)
        overlayContainer.pinToEdges(of: view)
    }

    private func setupMapView() {
        let imageView = UIImageView(image: UIImage(named: "map"))
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        mapViewContainer.addSubview(imageView)
        imageView.pinToEdges(of: mapViewContainer)
    }

    private func setupLocations() {
        let locations = [
            (x: 150, y: 110, label: "First"),
            (x: 210, y: 220, label: "Second"),
            (x: 180, y: 450, label: "Third"),
            (x: 270, y: 500, label: "Fourth"),
            (x: 150, y: 650, label: "Fifth")
        ]

        locations.forEach { setupLocation(x: CGFloat($0.x), y: CGFloat($0.y), label: $0.label) }
    }

    private func applyTiltTransform() {
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 500.0
        transform = CATransform3DScale(transform, 0.6, 1.0, 1)
        transform = CATransform3DRotate(transform, CGFloat(30 * Double.pi / 180), 2, 0, 0)
        mapViewContainer.layer.transform = transform
    }

    private func setupLocation(x: CGFloat, y: CGFloat, label: String) {
        // Icon image
        let icon = UIImageView(image: UIImage(named: "location"))
        icon.translatesAutoresizingMaskIntoConstraints = false
        overlayContainer.addSubview(icon)

        // Label background
        let labelBackground = UIView()
        labelBackground.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        labelBackground.layer.cornerRadius = 4
        labelBackground.translatesAutoresizingMaskIntoConstraints = false
        overlayContainer.addSubview(labelBackground)

        // Label
        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        labelBackground.addSubview(titleLabel)

        // Add tappable area as a transparent button **behind** icon
        let tappableButton = UIButton(type: .custom)
        tappableButton.backgroundColor = .clear
        tappableButton.accessibilityLabel = label.lowercased()
        tappableButton.addTarget(self, action: #selector(locationTapped(_:)), for: .touchUpInside)
        tappableButton.translatesAutoresizingMaskIntoConstraints = false
        overlayContainer.insertSubview(tappableButton, belowSubview: icon)

        // Constraints
        NSLayoutConstraint.activate([
            // Position icon where you want it
            icon.topAnchor.constraint(equalTo: overlayContainer.topAnchor, constant: y),
            icon.leadingAnchor.constraint(equalTo: overlayContainer.leadingAnchor, constant: x),

            // Position tappable button behind icon (same center, 124x124)
            tappableButton.centerXAnchor.constraint(equalTo: icon.centerXAnchor),
            tappableButton.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            tappableButton.widthAnchor.constraint(equalToConstant: 124),
            tappableButton.heightAnchor.constraint(equalToConstant: 124),

            // Position label background just below icon
            labelBackground.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 4),
            labelBackground.centerXAnchor.constraint(equalTo: icon.centerXAnchor),

            // Label padding
            titleLabel.topAnchor.constraint(equalTo: labelBackground.topAnchor, constant: 4),
            titleLabel.bottomAnchor.constraint(equalTo: labelBackground.bottomAnchor, constant: -4),
            titleLabel.leadingAnchor.constraint(equalTo: labelBackground.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: labelBackground.trailingAnchor, constant: -8)
        ])
    }


    @objc private func locationTapped(_ sender: UIButton) {
        guard let label = sender.accessibilityLabel else { return }
        let sheet = BottomSheetViewController(titleText: label)
        present(sheet, animated: false)
    }
    
}

// MARK: - Bottom Sheet ViewController

class BottomSheetViewController: UIViewController {

    private let titleText: String

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private var dimmedView: UIView!
    private var sheetHeightConstraint: NSLayoutConstraint!
    private let dragIndicator = UIView()
    private let try3DButton = UIButton(type: .system)

    // MARK: - Init

    init(titleText: String) {
        self.titleText = titleText
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupDimmedBackground()
        setupSheet()
        addPanGesture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateSheetIn()
    }

    // MARK: - Setup Views

    private func setupDimmedBackground() {
        dimmedView = UIView()
        dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        dimmedView.alpha = 0
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimmedView)

        NSLayoutConstraint.activate([
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        dimmedView.addGestureRecognizer(tap)

        UIView.animate(withDuration: 0.25) {
            self.dimmedView.alpha = 1
        }
    }

    private func setupSheet() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 20
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        view.addSubview(containerView)

        // Blur background (glassmorphism)
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.alpha = 0.7
        containerView.addSubview(blurView)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        sheetHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)
        sheetHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        // Drag indicator
        dragIndicator.translatesAutoresizingMaskIntoConstraints = false
        dragIndicator.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        dragIndicator.layer.cornerRadius = 3
        containerView.addSubview(dragIndicator)

        NSLayoutConstraint.activate([
            dragIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            dragIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            dragIndicator.widthAnchor.constraint(equalToConstant: 40),
            dragIndicator.heightAnchor.constraint(equalToConstant: 6)
        ])

        // Title Label
        titleLabel.text = titleText
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.alpha = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        // Subtitle Label
        subtitleLabel.text = subtitle(for: titleText)
        subtitleLabel.textColor = .white
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.alpha = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            titleLabel.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])

        setupTry3DButton()
    }

    private func setupTry3DButton() {
        try3DButton.translatesAutoresizingMaskIntoConstraints = false
        try3DButton.setTitle("Try 3D (\(titleText))", for: .normal)
        try3DButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        try3DButton.backgroundColor = UIColor.systemBlue
        try3DButton.setTitleColor(.white, for: .normal)
        try3DButton.layer.cornerRadius = 12
        try3DButton.alpha = 0 // start hidden
        try3DButton.addTarget(self, action: #selector(try3DButtonTapped), for: .touchUpInside)
        containerView.addSubview(try3DButton)

        NSLayoutConstraint.activate([
            try3DButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            try3DButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            try3DButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            try3DButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func subtitle(for title: String) -> String {
        switch title.lowercased() {
        case "first":
            return "A custom sheet in UIKit displays category selection using a native-style inline UIPickerView, similar to SwiftUI’s automatic picker."
        case "second":
            return "A UIKit custom sheet displays categories using an inline UIPickerView, mimicking SwiftUI's automatic picker style for seamless selection."
        case "third":
            return "A simple UIKit sheet shows categories with an inline UIPickerView, styled like SwiftUI’s automatic picker for easy selection."
        case "fourth":
            return "A UIKit sheet presents categories using an inline UIPickerView, styled like SwiftUI’s picker for smooth and easy user selection."
        case "fifth":
            return "A UIKit sheet features an inline UIPickerView for selecting categories, styled to look and feel like SwiftUI’s automatic picker."
        default:
            return ""
        }
    }

    // MARK: - Animations

    private func animateSheetIn() {
        view.layoutIfNeeded()
        sheetHeightConstraint.constant = view.frame.height * 0.4

        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: 0.25) {
                self.titleLabel.alpha = 1
                self.subtitleLabel.alpha = 1
                self.try3DButton.alpha = 1
            }
        })
    }

    // MARK: - Gestures

    private func addPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: containerView)

        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                sheetHeightConstraint.constant = view.frame.height * 0.4 - translation.y
            }
        case .ended:
            if translation.y > 100 {
                dismissSelf()
            } else {
                animateSheetIn()
            }
        default:
            break
        }
    }

    // MARK: - Actions

    @objc private func dismissSelf() {
        sheetHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
            self.dimmedView.alpha = 0
        }) { _ in
            self.dismiss(animated: false, completion: nil)
        }
    }

    @objc private func try3DButtonTapped() {
        let modelName = titleText.lowercased()
        let arVC = ARCamera(modelName: modelName)
        arVC.modalPresentationStyle = .fullScreen

        dismiss(animated: false) {
            if let topVC = UIApplication.shared.topMostViewController() {
                topVC.present(arVC, animated: true)
            }
        }
    }
}



// MARK: - UIView extension for easier pinning

private extension UIView {
    func pinToEdges(of superview: UIView) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor)
        ])
    }
}


                    
struct HomeViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> HomeViewController {
        return HomeViewController()
    }

    func updateUIViewController(_ uiViewController: HomeViewController, context: Context) {
        // Leave empty unless you want to update the view
    }
}

#Preview {
    HomeViewControllerPreview()
}
