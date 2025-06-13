//
//  Onboarding.swift
//  ARAccuracy
//
//  Created by Surya on 11/06/25.
//

import UIKit
import SwiftUI

class OnboardingViewController: UIViewController {
    
    // MARK: - UI Components
    private let firstCircle = UIView()
    private let secondCircle = UIView()
    private let thirdCircle = UIView()

    private var firstCircleWidthConstraint: NSLayoutConstraint!
    private var secondCircleWidthConstraint: NSLayoutConstraint!
    private var thirdCircleWidthConstraint: NSLayoutConstraint!
    
    private let nextButton = UIButton(type: .system)
    
    private let introLabel = UILabel()
    private let objectTitleLabel = UILabel()
    private let photoTitleLabel = UILabel()
    
    // MARK: - State
    private var activeIndex = 0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupProgressIndicators()
        setupNextButton()
        setupLabels()
        updateVisibleLabel()
    }
}

// MARK: - UI Setup
extension OnboardingViewController {
    
    private func setupProgressIndicators() {
        let stack = UIStackView(arrangedSubviews: [firstCircle, secondCircle, thirdCircle])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        setupCircle(firstCircle, initialWidth: 50, storeConstraintIn: &firstCircleWidthConstraint)
        setupCircle(secondCircle, initialWidth: 10, storeConstraintIn: &secondCircleWidthConstraint)
        setupCircle(thirdCircle, initialWidth: 10, storeConstraintIn: &thirdCircleWidthConstraint)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
    }
    
    private func setupNextButton() {
        nextButton.setTitle("Allow", for: .normal)
        nextButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(handleNextTapped), for: .touchUpInside)
        view.addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
    }
    
    private func setupCircle(_ circle: UIView, initialWidth: CGFloat, storeConstraintIn constraintRef: inout NSLayoutConstraint!) {
        circle.backgroundColor = .black
        circle.layer.cornerRadius = 5
        circle.translatesAutoresizingMaskIntoConstraints = false
        constraintRef = circle.widthAnchor.constraint(equalToConstant: initialWidth)
        constraintRef.isActive = true
        circle.heightAnchor.constraint(equalToConstant: 10).isActive = true
    }
    
    private func setupLabels() {
        configureLabel(introLabel, text: "Perkenalan aplikasi", fontSize: 30)
        configureLabel(objectTitleLabel, text: "Place 3D Object\n& Story behind 3D Building")
        configureLabel(photoTitleLabel, text: "Take Photo\n& with 3D Building")
        
        [introLabel, objectTitleLabel, photoTitleLabel].forEach {
            view.addSubview($0)
            $0.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -200).isActive = true
        }
        
        introLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        objectTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32).isActive = true
        photoTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32).isActive = true
    }
    
    private func configureLabel(_ label: UILabel, text: String, fontSize: CGFloat = 26) {
        label.text = text
        label.font = .systemFont(ofSize: fontSize, weight: .semibold)
        label.textColor = .black
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func updateVisibleLabel() {
        introLabel.isHidden = activeIndex != 0
        objectTitleLabel.isHidden = activeIndex != 1
        photoTitleLabel.isHidden = activeIndex != 2
    }
    
}
// MARK: - Transitions
extension OnboardingViewController {
    
    private func animateLabelTransition(from oldLabel: UILabel, to newLabel: UILabel) {
        oldLabel.alpha = 1
        UIView.animate(withDuration: 0.6) {
            oldLabel.alpha = 0
            oldLabel.transform = CGAffineTransform(translationX: -50, y: 0)
        }
        
        newLabel.alpha = 0
        newLabel.transform = CGAffineTransform(translationX: 50, y: 0)
        newLabel.isHidden = false
        
        UIView.animate(withDuration: 0.6, delay: 0.4, options: [], animations: {
            newLabel.alpha = 1
            newLabel.transform = .identity
        })
    }

    private func transitionToSecondStep() {
        firstCircleWidthConstraint.constant = 10
        secondCircleWidthConstraint.constant = 50
        nextButton.setTitle("Next", for: .normal)
        
        animateLabelTransition(from: introLabel, to: objectTitleLabel)
        
        UIView.animate(withDuration: 1.0) {
            self.view.layoutIfNeeded()
        }
        
        activeIndex = 1
    }
    
    private func transitionToFinalStep() {
        secondCircleWidthConstraint.constant = 10
        thirdCircleWidthConstraint.constant = 50
        nextButton.setTitle("Get Started", for: .normal)
        
        animateLabelTransition(from: objectTitleLabel, to: photoTitleLabel)
        
        UIView.animate(withDuration: 1.0) {
            self.view.layoutIfNeeded()
        }
        
        activeIndex = 2
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        let homeVC = HomeViewController()
        homeVC.modalPresentationStyle = .fullScreen
        
        let transition = CATransition()
        transition.duration = 0.4
        transition.type = .push
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.window?.layer.add(transition, forKey: kCATransition)
        present(homeVC, animated: false)
    }
    
}

// MARK: Actions
extension OnboardingViewController {
    
    @objc private func handleNextTapped() {
        switch activeIndex {
        case 0:
            transitionToSecondStep()
            
        case 1:
            transitionToFinalStep()
            
        case 2:
            completeOnboarding()
            
        default:
            break
        }
    }
}

struct OnboardingPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return OnboardingViewController()
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
