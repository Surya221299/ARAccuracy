//
//  ViewController.swift
//  ARAccuracy
//
//  Created by Surya on 24/05/25.
//

import UIKit
import SwiftUI

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Optionally add a splash image/logo
        let logo = UIImageView(image: UIImage(named: "logo"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logo)

        NSLayoutConstraint.activate([
            logo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logo.widthAnchor.constraint(equalToConstant: 120),
            logo.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if hasSeenOnboarding {
                // Navigate to Home directly
                let homeVC = HomeViewController()
                self.navigationController?.setViewControllers([homeVC], animated: true)
            } else {
                // Show onboarding
                let onboardingVC = OnboardingViewController()
                self.navigationController?.setViewControllers([onboardingVC], animated: true)
            }
        }
    }
}
                    
struct ViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // Leave empty unless you want to update the view
    }
}

#Preview {
    ViewControllerPreview()
}
