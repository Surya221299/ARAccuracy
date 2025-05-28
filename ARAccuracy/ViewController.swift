//
//  ViewController.swift
//  ARAccuracy
//
//  Created by Surya on 24/05/25.
//

import UIKit
import RealityKit
import ARKit
import Photos

class ViewController: UIViewController {
    
    private var placedAnchor: AnchorEntity?
    
    let captureButton = UIButton(type: .system)
    
    let deleteButton = UIButton(type: .system)
    
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
}

// MARK: Actions
private extension ViewController {
    
    @objc private func placeObjectTapped() {
        placeObject()
    }
    
    @objc private func deleteObjectTapped() {
        if let anchor = placedAnchor {
            anchor.removeFromParent()
            placedAnchor = nil
        }
        
        // Hide the overlay label
        UIView.animate(withDuration: 0.3) {
            self.overlayLabel.alpha = 0
        }
    }
    
    @objc private func captureImageTapped() {
        let renderer = UIGraphicsImageRenderer(size: arView.bounds.size)
        let capturedImage = renderer.image { ctx in
            arView.drawHierarchy(in: arView.bounds, afterScreenUpdates: true)
        }
        
        // 1. White flash animation
        let flashView = UIView(frame: arView.bounds)
        flashView.backgroundColor = .white
        flashView.alpha = 0
        view.addSubview(flashView)

        UIView.animate(withDuration: 0.3, animations: {
            flashView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.5, animations: {
                flashView.alpha = 0
            }) { _ in
                flashView.removeFromSuperview()
            }
        }

        // 2. Screenshot preview animation (portrait aspect ratio)
        let imageView = UIImageView(image: capturedImage)
        imageView.frame = arView.frame
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill

        // 🔲 Add white stroke
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 2

        view.addSubview(imageView)

        // Portrait rectangle dimensions
        let previewWidth: CGFloat = 90
        let previewHeight: CGFloat = 160
        let safeTop = view.safeAreaInsets.top
        let endFrame = CGRect(
            x: view.bounds.width - previewWidth - 16,
            y: safeTop + 16,
            width: previewWidth,
            height: previewHeight
        )

        UIView.animate(withDuration: 0.6, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            imageView.frame = endFrame
            imageView.alpha = 0.9
            imageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            // Keep it for 1.5 seconds, then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                UIView.animate(withDuration: 0.3, animations: {
                    imageView.alpha = 0
                }) { _ in
                    imageView.removeFromSuperview()
                }
            }

            // 3. Save to photo library (non-blocking)
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil)
                } else {
                    print("Photo library access denied.")
                }
            }
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
        setupDeleteButton()
        setupOverlayLabel()
        setupCaptureButton()
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
    
    private func setupDeleteButton() {
        deleteButton.setTitle("Delete Object", for: .normal)
        deleteButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        deleteButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.layer.cornerRadius = 10
        deleteButton.addTarget(self, action: #selector(deleteObjectTapped), for: .touchUpInside)
        
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            deleteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: placeButton.topAnchor, constant: -15),
            deleteButton.widthAnchor.constraint(equalToConstant: 160),
            deleteButton.heightAnchor.constraint(equalToConstant: 50)
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
    
    private func setupCaptureButton() {
        captureButton.setTitle("Capture Image", for: .normal)
        captureButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        captureButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.layer.cornerRadius = 10
        captureButton.addTarget(self, action: #selector(captureImageTapped), for: .touchUpInside)

        captureButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButton)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: deleteButton.topAnchor, constant: -15),
            captureButton.widthAnchor.constraint(equalToConstant: 160),
            captureButton.heightAnchor.constraint(equalToConstant: 50)
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
    
    private func placeObject() {
        guard let cameraTransform = arView.session.currentFrame?.camera.transform else { return }
        
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -2.0
        let transform = simd_mul(cameraTransform, translation)
        
        let anchor = AnchorEntity(world: transform)
        placedAnchor = anchor
        arView.scene.addAnchor(anchor)
        
        do {
            let modelEntity = try ModelEntity.loadModel(named: "pohon")
            modelEntity.setScale(SIMD3<Float>(repeating: 0.001), relativeTo: nil)
            anchor.addChild(modelEntity)
            showOverlayText()
        } catch {
            print("Failed to load model:", error)
        }
    }
}

