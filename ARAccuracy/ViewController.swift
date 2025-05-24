//
//  ViewController.swift
//  ARAccuracy
//
//  Created by Surya on 24/05/25.
//

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController {

    let arView = ARView(frame: .zero)
    let placeButton = UIButton(type: .system)
    private var cancellables = Set<AnyCancellable>()


    override func viewDidLoad() {
        super.viewDidLoad()

        setupARView()
        setupButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }

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

    private func startSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic

        arView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }

    @objc private func placeObjectTapped() {
        Task {
            await placeObject()
        }
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
        } catch {
            print("Failed to load model:", error)
        }
    }


}
