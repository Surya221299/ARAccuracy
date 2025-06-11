//
//  Onboarding.swift
//  ARAccuracy
//
//  Created by Surya on 11/06/25.
//

import UIKit
import SwiftUI
import AVFoundation
import Photos

class Onboarding: UIViewController {
    
    private let firstCircle = UIView()
    private let secondCircle = UIView()
    private let thirdCircle = UIView()
    
    private var firstCircleWidthConstraint: NSLayoutConstraint!
    private var secondCircleWidthConstraint: NSLayoutConstraint!
    private var thirdCircleWidthConstraint: NSLayoutConstraint!
    
    private var activeIndex = 0
    private let nextButton = UIButton(type: .system)
    
    // Labels for 3 states
    private let introLabel = UILabel()
    private let objectTitleLabel = UILabel()
    private let objectSubtitleLabel = UILabel()
    private let photoTitleLabel = UILabel()
    private let photoSubtitleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupBottomViews()
        setupLabels()
        updateLabelVisibility()
    }
    
    private func setupBottomViews() {
        let circlesContainer = UIStackView()
        circlesContainer.axis = .horizontal
        circlesContainer.spacing = 10
        circlesContainer.alignment = .center
        circlesContainer.translatesAutoresizingMaskIntoConstraints = false
        
        setupCircle(firstCircle, width: 50)
        setupCircle(secondCircle, width: 10)
        setupCircle(thirdCircle, width: 10)
        
        circlesContainer.addArrangedSubview(firstCircle)
        circlesContainer.addArrangedSubview(secondCircle)
        circlesContainer.addArrangedSubview(thirdCircle)
        
        view.addSubview(circlesContainer)
        
        nextButton.setTitle("Allow", for: .normal)
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(handleNextTapped), for: .touchUpInside)
        view.addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            circlesContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            circlesContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
    }
    
    private func setupCircle(_ circle: UIView, width: CGFloat) {
        circle.backgroundColor = .black
        circle.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = circle.widthAnchor.constraint(equalToConstant: width)
        widthConstraint.isActive = true
        circle.heightAnchor.constraint(equalToConstant: 10).isActive = true
        circle.layer.cornerRadius = 5.0
        
        switch circle {
        case firstCircle: firstCircleWidthConstraint = widthConstraint
        case secondCircle: secondCircleWidthConstraint = widthConstraint
        case thirdCircle: thirdCircleWidthConstraint = widthConstraint
        default: break
        }
    }
    
    private func setupLabels() {
        // First state
        introLabel.text = "Perkenalan aplikasi"
        introLabel.font = .systemFont(ofSize: 30, weight: .semibold)
        introLabel.textColor = .black
        introLabel.textAlignment = .left
        introLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Second state
        objectTitleLabel.text = "Place 3d Object\n& Story behind 3D Building"
        objectTitleLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        objectTitleLabel.textAlignment = .left
        objectTitleLabel.textColor = .black
        objectTitleLabel.numberOfLines = 0
        objectTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        objectSubtitleLabel.text = "place your 3d object front of your camera and you will get story behind 3D building in kampung vietnam"
        objectSubtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        objectSubtitleLabel.textAlignment = .left
        objectSubtitleLabel.textColor = .black
        objectSubtitleLabel.numberOfLines = 0
        objectSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Third state
        photoTitleLabel.text = "Take photo\n& with 3D Building"
        photoTitleLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        photoTitleLabel.textAlignment = .left
        photoTitleLabel.textColor = .black
        photoTitleLabel.numberOfLines = 0
        photoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        photoSubtitleLabel.text = "capture image with 3D Building inside it"
        photoSubtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        photoSubtitleLabel.textAlignment = .left
        photoSubtitleLabel.textColor = .black
        photoSubtitleLabel.numberOfLines = 0
        photoSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to view
        view.addSubview(introLabel)
        view.addSubview(objectTitleLabel)
        view.addSubview(objectSubtitleLabel)
        view.addSubview(photoTitleLabel)
        view.addSubview(photoSubtitleLabel)
        
        NSLayoutConstraint.activate([
            introLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            introLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            objectTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            objectTitleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            objectSubtitleLabel.topAnchor.constraint(equalTo: objectTitleLabel.bottomAnchor, constant: 12),
            objectSubtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            objectSubtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            photoTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            photoTitleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            photoSubtitleLabel.topAnchor.constraint(equalTo: photoTitleLabel.bottomAnchor, constant: 12),
            photoSubtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            photoSubtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }
    
    private func updateLabelVisibility() {
        introLabel.isHidden = activeIndex != 0
        
        let isSecond = activeIndex == 1
        objectTitleLabel.isHidden = !isSecond
        objectSubtitleLabel.isHidden = !isSecond
        
        let isThird = activeIndex == 2
        photoTitleLabel.isHidden = !isThird
        photoSubtitleLabel.isHidden = !isThird
    }
    
    private func transitionToSecondState() {
        firstCircleWidthConstraint.constant = 10
        secondCircleWidthConstraint.constant = 50
        nextButton.setTitle("Next", for: .normal)
        
        UIView.animate(withDuration: 1.0, animations: {
            self.introLabel.alpha = 0
            self.introLabel.transform = CGAffineTransform(translationX: -50, y: 0)
        })
        
        objectTitleLabel.alpha = 0
        objectTitleLabel.transform = CGAffineTransform(translationX: 50, y: 0)
        objectSubtitleLabel.alpha = 0
        objectSubtitleLabel.transform = CGAffineTransform(translationX: 50, y: 0)
        
        objectTitleLabel.isHidden = false
        objectSubtitleLabel.isHidden = false
        
        UIView.animate(withDuration: 1.0, delay: 0.9, options: [], animations: {
            self.objectTitleLabel.alpha = 1
            self.objectTitleLabel.transform = .identity
            self.objectSubtitleLabel.alpha = 1
            self.objectSubtitleLabel.transform = .identity
        })
        
        UIView.animate(withDuration: 1.5) {
            self.view.layoutIfNeeded()
        }
        
        activeIndex = 1
    }
    
    private func requestCameraAndPhotoLibraryPermissions(completion: @escaping (Bool, Bool) -> Void) {
        var cameraGranted = false
        var photoGranted = false
        
        let group = DispatchGroup()
        
        group.enter()
        AVCaptureDevice.requestAccess(for: .video) { granted in
            cameraGranted = granted
            group.leave()
        }
        
        group.enter()
        PHPhotoLibrary.requestAuthorization { status in
            if #available(iOS 14, *) {
                photoGranted = (status == .authorized || status == .limited)
            } else {
                photoGranted = (status == .authorized)
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(cameraGranted, photoGranted)
        }
    }
    
    @objc private func handleNextTapped() {
        // Reset all circle widths
        firstCircleWidthConstraint.constant = 10
        secondCircleWidthConstraint.constant = 10
        thirdCircleWidthConstraint.constant = 10
        
        switch activeIndex {
        case 0:
            firstCircleWidthConstraint.constant = 50
            requestCameraAndPhotoLibraryPermissions { cameraGranted, photoGranted in
                DispatchQueue.main.async {
                    if cameraGranted && photoGranted {
                        self.transitionToSecondState()
                    } else {
                        let alert = UIAlertController(title: "Permissions Required",
                                                      message: "Camera and Photo Library access is needed. Please enable them in Settings.",
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                        })
                        self.present(alert, animated: true)
                    }
                }
            }
            
        case 1:
            thirdCircleWidthConstraint.constant = 50
            nextButton.setTitle("Get Started", for: .normal)
            
            UIView.animate(withDuration: 1.0, animations: {
                self.objectTitleLabel.alpha = 0
                self.objectTitleLabel.transform = CGAffineTransform(translationX: -50, y: 0)
                self.objectSubtitleLabel.alpha = 0
                self.objectSubtitleLabel.transform = CGAffineTransform(translationX: -50, y: 0)
            })
            
            photoTitleLabel.alpha = 0
            photoTitleLabel.transform = CGAffineTransform(translationX: 50, y: 0)
            photoSubtitleLabel.alpha = 0
            photoSubtitleLabel.transform = CGAffineTransform(translationX: 50, y: 0)
            photoTitleLabel.isHidden = false
            photoSubtitleLabel.isHidden = false
            
            UIView.animate(withDuration: 1.0, delay: 0.9, options: [], animations: {
                self.photoTitleLabel.alpha = 1
                self.photoTitleLabel.transform = .identity
                self.photoSubtitleLabel.alpha = 1
                self.photoSubtitleLabel.transform = .identity
            })
            
            UIView.animate(withDuration: 1.5) {
                self.view.layoutIfNeeded()
            }
            
            activeIndex = min(activeIndex + 1, 2)
            
        default:
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            
            let homeVC = HomeViewController()
            homeVC.modalPresentationStyle = .fullScreen
            
            let transition = CATransition()
            transition.duration = 0.4
            transition.type = .push
            transition.subtype = .fromRight
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            self.view.window?.layer.add(transition, forKey: kCATransition)
            self.present(homeVC, animated: false)
        }
    }
}

struct OnboardingPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return Onboarding()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Leave empty for static previews
    }
}

struct ViewController_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPreview()
            .edgesIgnoringSafeArea(.all) // Optional: to see full-screen layout
            .previewDevice("iPhone 14 Pro") // Choose your target device
    }
}
