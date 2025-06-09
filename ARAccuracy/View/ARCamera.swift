//
//  ARCamera.swift
//  ARAccuracy
//
//  Created by Surya on 09/06/25.
//

import UIKit
import RealityKit
import ARKit
import Photos

class ARCamera: UIViewController {
    
    // MARK: - UI Elements
    private let arView = ARView(frame: .zero)
    private let placeButton = ARPlaceButton()
    private var deleteGlassButton: CircularGlassButton!
    private var historyGlassButton: CircularGlassButton!
    private var rotateGlassButton: CircularGlassButton!
    private let captureButton = UIButton(type: .system)
    private let instructionLabel = PaddedLabel()
    private let overlayLabel = UILabel()
    private let imageButton = UIButton(type: .system)
    private let imageIconView = UIImageView()
    private let imageRectangle = UIView()
    private var isRotationEnabled = false
    private var isRotateButtonBlue = false
    
    // MARK: - AR State
    private let modelName: String
    private let labelText: String
    private var placedAnchor: AnchorEntity?
    private var previewEntity: ModelEntity?
    private var previewAnchor: AnchorEntity?
    private var modelDistance: Float = -2.0
    private var hasDetectedSurface = false
    private var displayLink: CADisplayLink?
    private var hasPlacedObject = false
    
    // MARK: - Init
    init(modelName: String, labelText: String? = nil) {
        self.modelName = modelName
        self.labelText = labelText ?? modelName.capitalized
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupUI()
        setupBackButton()
        setupGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
        displayLink = CADisplayLink(target: self, selector: #selector(performSurfaceRaycast))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
        displayLink?.invalidate()
        displayLink = nil
    }
    
    deinit {
        print("🔁 ARCamera deinitialized")
    }
}

// MARK: - Setup
private extension ARCamera {
    
    func setupARView() {
        arView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arView)
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func setupUI() {
        setupGlassmorphismOverlay()
        setupPlaceButton()
        setupCaptureButton(hidden: true)
        setupInstructionLabel()
        setupOverlayLabel()
        setupImageRectangle(hidden: true)
        setupDeleteButton()
        setupHistoryButton()
        setupRotateButton()
        
    }
    
    func setupGestures() {
        arView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(rotateObject(_:))))
        arView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
    }
    
    func setupGlassmorphismOverlay() {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 20
        blurView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        blurView.clipsToBounds = true
        view.addSubview(blurView)
        
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurView.heightAnchor.constraint(equalToConstant: 170)
        ])
    }
    
    func setupPlaceButton() {
        placeButton.addTarget(self, action: #selector(placeObjectTapped), for: .touchUpInside)
        placeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeButton)
        
        NSLayoutConstraint.activate([
            placeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            placeButton.widthAnchor.constraint(equalToConstant: 80),
            placeButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func setupImageButton() {
        imageButton.backgroundColor = .black
        imageButton.layer.cornerRadius = 8
        imageButton.layer.borderWidth = 2
        imageButton.layer.borderColor = UIColor.white.cgColor
        imageButton.clipsToBounds = true
        
        // Smooth corner on iOS 13+
        if #available(iOS 13.0, *) {
            imageButton.layer.cornerCurve = .continuous
        }
        
        // Set icon image
        let iconImage = UIImage(named: "image")
        let iconImageView = UIImageView(image: iconImage)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        imageButton.addSubview(iconImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: imageButton.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: imageButton.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        imageButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageButton)
        
        NSLayoutConstraint.activate([
            imageButton.centerYAnchor.constraint(equalTo: placeButton.centerYAnchor),
            imageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 48),
            imageButton.widthAnchor.constraint(equalToConstant: 55),
            imageButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func setupImageRectangle(hidden: Bool = false) {
        imageRectangle.backgroundColor = .black
        imageRectangle.layer.cornerRadius = 8
        imageRectangle.layer.borderColor = UIColor.white.cgColor
        imageRectangle.layer.borderWidth = 2
        imageRectangle.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            imageRectangle.layer.cornerCurve = .continuous
        }
        
        // Configure imageIconView
        imageIconView.contentMode = .scaleAspectFit
        imageIconView.clipsToBounds = true
        imageIconView.layer.cornerRadius = 8
        imageIconView.layer.cornerCurve = .continuous
        imageIconView.translatesAutoresizingMaskIntoConstraints = false
        imageIconView.image = UIImage(named: "image")
        imageRectangle.addSubview(imageIconView)
        
        // Add fixed size constraints (only for the placeholder)
        NSLayoutConstraint.activate([
            imageIconView.centerXAnchor.constraint(equalTo: imageRectangle.centerXAnchor),
            imageIconView.centerYAnchor.constraint(equalTo: imageRectangle.centerYAnchor),
            imageIconView.widthAnchor.constraint(equalToConstant: 34),
            imageIconView.heightAnchor.constraint(equalToConstant: 34)
        ])
        
        imageRectangle.alpha = hidden ? 0 : 1
        imageRectangle.isHidden = hidden
        view.insertSubview(imageRectangle, belowSubview: placeButton)
        
        NSLayoutConstraint.activate([
            imageRectangle.centerYAnchor.constraint(equalTo: placeButton.centerYAnchor),
            imageRectangle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 48),
            imageRectangle.widthAnchor.constraint(equalToConstant: 55),
            imageRectangle.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func setupDeleteButton() {
        let redColor = UIColor(red: 1.0, green: 0.365, blue: 0.365, alpha: 1.0) // #FF5D5D
        deleteGlassButton = CircularGlassButton(imageName: "trash", tintColor: redColor)
        deleteGlassButton.alpha = 0
        deleteGlassButton.isHidden = true
        
        view.addSubview(deleteGlassButton)
        NSLayoutConstraint.activate([
            deleteGlassButton.widthAnchor.constraint(equalToConstant: 48),
            deleteGlassButton.heightAnchor.constraint(equalToConstant: 48),
            deleteGlassButton.centerYAnchor.constraint(equalTo: instructionLabel.centerYAnchor),
            deleteGlassButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
        
        deleteGlassButton.button.addTarget(self, action: #selector(deleteObjectTapped), for: .touchUpInside)
    }
    
    func setupHistoryButton() {
        historyGlassButton = CircularGlassButton(imageName: "history", tintColor: .white)
        historyGlassButton.alpha = 0
        historyGlassButton.isHidden = true
        
        view.addSubview(historyGlassButton)
        NSLayoutConstraint.activate([
            historyGlassButton.widthAnchor.constraint(equalToConstant: 48),
            historyGlassButton.heightAnchor.constraint(equalToConstant: 48),
            historyGlassButton.topAnchor.constraint(equalTo: deleteGlassButton.bottomAnchor, constant: 16),
            historyGlassButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
        
        historyGlassButton.button.addTarget(self, action: #selector(historyButtonTapped), for: .touchUpInside)
    }
    
    func setupRotateButton() {
        rotateGlassButton = CircularGlassButton(imageName: "rotate", tintColor: .white)
        rotateGlassButton.button.addTarget(self, action: #selector(rotateButtonTapped), for: .touchUpInside)
        rotateGlassButton.alpha = 0
        rotateGlassButton.isHidden = true
        
        view.addSubview(rotateGlassButton)
        
        NSLayoutConstraint.activate([
            rotateGlassButton.widthAnchor.constraint(equalToConstant: 48),
            rotateGlassButton.heightAnchor.constraint(equalToConstant: 48),
            rotateGlassButton.topAnchor.constraint(equalTo: historyGlassButton.bottomAnchor, constant: 16),
            rotateGlassButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }
    
    func setupCaptureButton(hidden: Bool = false) {
        // Style the captureButton as a custom circle
        captureButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        captureButton.layer.cornerRadius = 25
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.layer.borderWidth = 0.5
        captureButton.clipsToBounds = true
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add camera icon
        let iconImageView = UIImageView(image: UIImage(named: "camera"))
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addSubview(iconImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: captureButton.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        captureButton.addTarget(self, action: #selector(captureImageTapped), for: .touchUpInside)
        captureButton.alpha = hidden ? 0 : 1
        captureButton.isHidden = hidden
        view.insertSubview(captureButton, belowSubview: placeButton)
        
        NSLayoutConstraint.activate([
            captureButton.centerYAnchor.constraint(equalTo: placeButton.centerYAnchor),
            captureButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -48),
            captureButton.widthAnchor.constraint(equalToConstant: 50),
            captureButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func setupInstructionLabel() {
        instructionLabel.text = "Detecting Surface"
        instructionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        instructionLabel.textColor = .white
        instructionLabel.backgroundColor = .red
        instructionLabel.textAlignment = .center
        instructionLabel.layer.cornerRadius = 8
        instructionLabel.clipsToBounds = true
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            instructionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
    }
    
    func setupOverlayLabel() {
        overlayLabel.text = labelText
        overlayLabel.font = UIFont.boldSystemFont(ofSize: 24)
        overlayLabel.textColor = .white
        overlayLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlayLabel.textAlignment = .center
        overlayLabel.layer.cornerRadius = 8
        overlayLabel.clipsToBounds = true
        overlayLabel.alpha = 0
        overlayLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayLabel)
        NSLayoutConstraint.activate([
            overlayLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            overlayLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlayLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            overlayLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
    }
    
    func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backButton.layer.cornerRadius = 18
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
}

// MARK: Actions
private extension ARCamera {
    
    @objc private func placeObjectTapped() {
        guard !hasPlacedObject else { return }
        hasPlacedObject = true
        placeObject()
        
        placeButton.isEnabled = false
        placeButton.alpha = 0.3
        
        // Setup hidden initially
        if imageRectangle.superview == nil {
            setupImageRectangle(hidden: true)
        }
        if captureButton.superview == nil {
            setupCaptureButton(hidden: true)
        }
        
        view.layoutIfNeeded()
        
        // Bring to back behind placeButton
        view.insertSubview(imageRectangle, belowSubview: placeButton)
        view.insertSubview(captureButton, belowSubview: placeButton)
        
        // Start small and semi-transparent at center of placeButton
        [imageRectangle, captureButton].forEach {
            $0.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            $0.center = placeButton.center
            $0.alpha = 0.2 // Start at 20% opacity
            $0.isHidden = false
        }
        
        // Animate to normal size and full opacity
        UIView.animate(withDuration: 2.0,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.4,
                       options: [.curveEaseInOut],
                       animations: {
            self.imageRectangle.transform = .identity
            self.captureButton.transform = .identity
            self.imageRectangle.alpha = 1.0
            self.captureButton.alpha = 1.0
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.imageRectangle.translatesAutoresizingMaskIntoConstraints = false
            self.captureButton.translatesAutoresizingMaskIntoConstraints = false
            
            if self.overlayLabel.superview == nil {
                self.setupOverlayLabel()
            }
            
        })
        
        instructionLabel.isHidden = true
        
        deleteGlassButton.alpha = 0
        deleteGlassButton.isHidden = false
        historyGlassButton.alpha = 0
        historyGlassButton.isHidden = false
        rotateGlassButton.alpha = 0
        rotateGlassButton.isHidden = false
        
        
        UIView.animate(withDuration: 0.3) {
            self.deleteGlassButton.alpha = 1.0
            self.historyGlassButton.alpha = 1.0
            self.rotateGlassButton.alpha = 1.0
        }
        
    }
    
    @objc private func deleteObjectTapped() {
        if let anchor = placedAnchor {
            anchor.removeFromParent()
            placedAnchor = nil
        }
        
        hasPlacedObject = false // 🔁 allow placement again
        captureButton.isHidden = true
        placeButton.isEnabled = true
        placeButton.alpha = 1.0
        showPreviewModel()
        overlayLabel.removeFromSuperview()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.deleteGlassButton.alpha = 0
            self.historyGlassButton.alpha = 0
            self.rotateGlassButton.alpha = 0
        }) { _ in
            self.deleteGlassButton.isHidden = true
            self.historyGlassButton.isHidden = true
            self.rotateGlassButton.isHidden = true
        }
        
        instructionLabel.isHidden = false
        
    }
    
    @objc private func historyButtonTapped() {
        print("history tapped")
    }
    
    @objc private func captureImageTapped() {
        let capturedImage = captureARViewImage()
        
        showWhiteFlash()
        
        let preview = createPreviewImageView(with: capturedImage)
        view.addSubview(preview)
        
        animatePreview(preview) {
            self.saveImageToPhotoLibrary(capturedImage)
        }
        
        // Show captured image in the left rectangle (imageRectangle)
        self.imageIconView.image = capturedImage
        self.imageIconView.contentMode = .scaleAspectFill
        self.imageIconView.clipsToBounds = true
        
        // Stretch imageIconView to fill imageRectangle
        NSLayoutConstraint.deactivate(imageIconView.constraints)
        imageIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageIconView.topAnchor.constraint(equalTo: imageRectangle.topAnchor),
            imageIconView.bottomAnchor.constraint(equalTo: imageRectangle.bottomAnchor),
            imageIconView.leadingAnchor.constraint(equalTo: imageRectangle.leadingAnchor),
            imageIconView.trailingAnchor.constraint(equalTo: imageRectangle.trailingAnchor)
        ])
    }
    
    
    @objc private func rotateObject(_ gesture: UIPanGestureRecognizer) {
        guard isRotateButtonBlue else { return }
        guard let anchor = placedAnchor,
              let modelEntity = anchor.children.first as? ModelEntity else { return }
        
        let translation = gesture.translation(in: arView)
        let sensitivity: Float = 1.5
        
        let angleY = Float(translation.x) * (Float.pi / 180) * sensitivity
        modelEntity.transform.rotation = simd_mul(
            modelEntity.transform.rotation,
            simd_quatf(angle: angleY, axis: SIMD3<Float>(0, 1, 0)) // 🔁 Rotate around Y instead of X
        )
        
        gesture.setTranslation(.zero, in: arView)
    }
    
    @objc private func performSurfaceRaycast() {
        
        if hasPlacedObject {
            return // ✅ Do nothing if already placed
        }
        
        let center = arView.center
        let results = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .horizontal)
        
        let surfaceFound = !results.isEmpty
        
        // Update place button
        placeButton.isEnabled = surfaceFound
        placeButton.alpha = surfaceFound ? 1.0 : 0.3
        
        // Sync instruction label with button state
        if surfaceFound {
            instructionLabel.text = "Place object"
            instructionLabel.backgroundColor = UIColor.green
        } else {
            instructionLabel.text = "Detecting Surface"
            instructionLabel.backgroundColor = UIColor.red
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard isRotateButtonBlue else { return }
        let zoomSpeed: Float = 0.3
        let scale = Float(gesture.scale)
        
        // Flip the direction so pinch out (scale > 1) moves object closer (less negative)
        let delta = (scale - 1.0) * zoomSpeed
        
        // Adjust model distance — increase to move farther (more negative), decrease to move closer (less negative)
        modelDistance += delta
        
        // Clamp between a reasonable range
        let minDistance: Float = -5.0
        let maxDistance: Float = -0.2
        modelDistance = min(max(modelDistance, minDistance), maxDistance)
        
        // Reset scale to avoid compounding
        gesture.scale = 1.0
        
        // Apply to the preview model
        if let previewAnchor = previewAnchor {
            previewAnchor.position = [0, 0, modelDistance]
        }
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func rotateButtonTapped() {
        isRotateButtonBlue.toggle()
        
        let newColor: UIColor = isRotateButtonBlue ? .systemBlue : .white
        rotateGlassButton.button.tintColor = newColor
    }
    
}

// MARK: AR - SetUp
private extension ARCamera {
    
    private func updateInstructionForSurfaceFound() {
        guard !hasDetectedSurface else { return }
        hasDetectedSurface = true
        
        instructionLabel.text = "Place object now"
        instructionLabel.backgroundColor = UIColor.green
    }
    
    private func showOverlayText() {
        UIView.animate(withDuration: 0.3) {
            self.overlayLabel.alpha = 1
        }
    }
}

// MARK: AR Handling

private extension ARCamera {
    
    private func startSession() {
        
        hasDetectedSurface = false // 🔁 reset surface detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
        
        showPreviewModel()
    }
    
    private func showPreviewModel() {
        do {
            let model = try ModelEntity.loadModel(named: modelName)
            model.setScale(SIMD3<Float>(repeating: 0.001), relativeTo: nil)
            
            var updatedMaterials: [Material] = []
            
            for _ in model.model?.materials ?? [] {
                let transparentMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.2), isMetallic: false)
                updatedMaterials.append(transparentMaterial)
            }
            
            model.model?.materials = updatedMaterials
            
            let cameraAnchor = AnchorEntity(.camera)
            cameraAnchor.position = [0, 0, modelDistance]
            cameraAnchor.addChild(model)
            arView.scene.anchors.append(cameraAnchor)
            
            previewAnchor = cameraAnchor
            previewEntity = model
        } catch {
            print("Failed to load preview model:", error)
        }
    }
    
    private func createTransparentMaterial() -> SimpleMaterial {
        let color = UIColor.white.withAlphaComponent(0.5)
        return SimpleMaterial(color: color, isMetallic: false)
    }
    
    private func placeObject() {
        // Remove the preview anchor
        if let preview = previewAnchor {
            arView.scene.anchors.remove(preview)
            previewAnchor = nil
            previewEntity = nil
        }
        
        // Raycast from screen center to find a horizontal surface
        let center = arView.center
        let results = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .horizontal)
        
        guard let firstResult = results.first else {
            print("No surface found to place object.")
            return
        }
        
        let arAnchor = ARAnchor(transform: firstResult.worldTransform)
        arView.session.add(anchor: arAnchor)
        
        let anchor = AnchorEntity(anchor: arAnchor)
        placedAnchor = anchor
        arView.scene.addAnchor(anchor)
        
        do {
            let modelEntity = try ModelEntity.loadModel(named: modelName)
            modelEntity.setScale(SIMD3<Float>(repeating: 0.01), relativeTo: nil)
            anchor.addChild(modelEntity)
            showOverlayText()
        } catch {
            print("Failed to load model:", error)
        }
        
        captureButton.isHidden = false
        instructionLabel.isHidden = true
    }
    
}

// MARK: Image Capture Handling
extension ARCamera {
    
    private func captureARViewImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: arView.bounds.size)
        return renderer.image { ctx in
            arView.drawHierarchy(in: arView.bounds, afterScreenUpdates: true)
        }
    }
    
    private func showWhiteFlash() {
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
    }
    
    private func createPreviewImageView(with image: UIImage) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.frame = arView.frame
        imageView.layer.cornerRadius = 12
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 2
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }
    
    private func animatePreview(_ imageView: UIImageView, completion: @escaping () -> Void) {
        let previewWidth: CGFloat = 90
        let previewHeight: CGFloat = 160
        let safeTop = view.safeAreaInsets.top
        
        let endFrame = CGRect(
            x: view.bounds.width - previewWidth - 16,
            y: safeTop + 16,
            width: previewWidth,
            height: previewHeight
        )
        
        UIView.animate(withDuration: 0.6, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            imageView.frame = endFrame
            imageView.alpha = 0.9
            imageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                UIView.animate(withDuration: 0.3, animations: {
                    imageView.alpha = 0
                }) { _ in
                    imageView.removeFromSuperview()
                    completion()
                }
            }
        }
    }
    
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            } else {
                print("Photo library access denied.")
            }
        }
    }
    
}

