//
//  ViewController.swift
//  ARAccuracy
//
//  Created by Surya on 24/05/25.
//

import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController {
    
    let arView = ARView(frame: .zero)
    let placeButton = UIButton(type: .system)
    private let overlayLabel: UILabel = {
        let label = UILabel()
        label.text = "Pohon"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupARView()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }
    
    // MARK: Actions
    @objc private func placeObjectTapped() {
        Task {
            await placeObject()
        }
    }
}

// MARK: AR - SetUp
private extension ViewController {
    
    private func setupARView() {
        arView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arView)
        
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    func setupUI() {
        setupButton()
        setupOverlayLabel()
    }
    
    private func setupButton() {
        placeButton.setTitle("Place Object", for: .normal)
        placeButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        placeButton.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        placeButton.layer.cornerRadius = 10
        placeButton.addTarget(self, action: #selector(placeObjectTapped), for: .touchUpInside)
        
        placeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeButton)
        
        NSLayoutConstraint.activate([
            placeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            placeButton.widthAnchor.constraint(equalToConstant: 160),
            placeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupOverlayLabel() {
        view.addSubview(overlayLabel)
        NSLayoutConstraint.activate([
            overlayLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            overlayLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlayLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            overlayLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func showOverlayText() {
        UIView.animate(withDuration: 0.3) {
            self.overlayLabel.alpha = 1
        }
    }
}

// MARK: AR Handling

private extension ViewController {
    
    private func startSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        arView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    private func placeObject() async {
        guard let cameraTransform = arView.session.currentFrame?.camera.transform else { return }
        
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -2.0
        let transform = simd_mul(cameraTransform, translation)
        
        let anchor = AnchorEntity(world: transform)
        arView.scene.addAnchor(anchor)
        
        do {
            let modelEntity = try await ModelEntity(named: "pohon")
            modelEntity.setScale(SIMD3<Float>(repeating: 0.001), relativeTo: nil)
            anchor.addChild(modelEntity)
            showOverlayText()
        } catch {
            print("Failed to load model:", error)
        }
    }
}

