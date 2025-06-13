//
//  ARCamera.swift
//  ARAccuracy
//
//  Created by Surya on 09/06/25.
//

import UIKit
import RealityKit
import ARKit
import ImageIO

class ARCamera: UIViewController {
    
    // MARK: - UI Elements
    private let arView = ARView(frame: .zero)
    private let placeButton = ARPlaceButton()
    private var deleteGlassButton: CircularGlassButton!
    private var exitGlassButton: CircularGlassButton!
    private let instructionLabel = PaddedLabel()
    private var backButton: UIButton!
    private let overlayLabel = UILabel()
    private var isRotationEnabled = false
    private var isRotateButtonBlue = false
    private var blurView: UIVisualEffectView!
    private var glassOverlayVisible = true
    
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
    
    // MARK: History Played
    private var player: AVPlayer?
    private let subtitleLabel = UILabel()
    private var subtitles: [(time: TimeInterval, text: String)] = []
    private var timer: Timer?
    private let overlayImageView = UIImageView()
    private let subtitleBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
    private var subtitleExperienceStarted = false
    
    // MARK: 0.5, 1, 2, 3 X State
    private let values = ["0.5", "1", "2", "3"]
    private var selectedButton: UIButton?
    private var buttonWidthConstraints: [UIButton: NSLayoutConstraint] = [:]
    private var didSetupButtonStack = false
    private var scaleButtonBackgroundView: UIVisualEffectView!
    private var selectedScaleValue: Float = 1.0
    
    // Constants
    private let activeSize: CGFloat = 32
    private let inactiveSize: CGFloat = 24
    private let buttonFontSize: CGFloat = 10
    private let padding: CGFloat = 3
    
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
        setupInstructionLabel()
        setupOverlayLabel()
        setupDeleteButton()
        setupExitButton()
        setupButtonStack()
    }
    
    func setupGlassmorphismOverlay() {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        blurView = UIVisualEffectView(effect: blur)
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
        backButton = UIButton(type: .system)
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
    
    
    func setupExitButton() {
        
        let exitColor = UIColor(red: 1.0, green: 0.298, blue: 0.337, alpha: 1.0) // #FF4C56
        exitGlassButton = CircularGlassButton(imageName: "exit", tintColor: .white)
        exitGlassButton.setBackgroundColor(exitColor)
        
        exitGlassButton.alpha = 0
        exitGlassButton.isHidden = true
        
        view.addSubview(exitGlassButton)
        NSLayoutConstraint.activate([
            exitGlassButton.widthAnchor.constraint(equalToConstant: 48),
            exitGlassButton.heightAnchor.constraint(equalToConstant: 48),
            exitGlassButton.topAnchor.constraint(equalTo: deleteGlassButton.bottomAnchor, constant: 16),
            exitGlassButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
        
        view.bringSubviewToFront(exitGlassButton)
        
        exitGlassButton.button.addTarget(self, action: #selector(exitButtonTapped), for: .touchUpInside)
    }
    
    // MARK: History Active state
    
    private func setupSubtitleLabel() {
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        subtitleLabel.textColor = .white
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleBackgroundView.contentView.addSubview(subtitleLabel)
        subtitleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        subtitleBackgroundView.layer.cornerRadius = 12
        subtitleBackgroundView.clipsToBounds = true
        subtitleBackgroundView.alpha = 0.9
        
        view.addSubview(subtitleBackgroundView)
        
        // Constraints for background view
        NSLayoutConstraint.activate([
            subtitleBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            subtitleBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
        ])
        
        // Constraints for the label inside the background
        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(equalTo: subtitleBackgroundView.leadingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: subtitleBackgroundView.trailingAnchor, constant: -12),
            subtitleLabel.topAnchor.constraint(equalTo: subtitleBackgroundView.topAnchor, constant: 8),
            subtitleLabel.bottomAnchor.constraint(equalTo: subtitleBackgroundView.bottomAnchor, constant: -8)
        ])
    }
    
    
    private func loadSubtitles() {
        guard let url = Bundle.main.url(forResource: "subtitles", withExtension: "vtt"),
              let contents = try? String(contentsOf: url) else {
            print("Failed to load subtitles")
            return
        }
        
        subtitles = parseWebVTT(contents)
    }
    
    private func playAudio() {
        // Set audio session category to allow playback in silent mode
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        
        guard let audioURL = Bundle.main.url(forResource: "audio", withExtension: "m4a") else {
            print("Missing audio file")
            return
        }
        
        let playerItem = AVPlayerItem(url: audioURL)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        startSubtitleTimer()
    }
    
    private func startSubtitleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self,
                  let currentTime = self.player?.currentTime().seconds else { return }
            
            for (index, subtitle) in self.subtitles.enumerated() {
                let nextTime = index + 1 < self.subtitles.count ? self.subtitles[index + 1].time : .infinity
                if currentTime >= subtitle.time && currentTime < nextTime {
                    self.subtitleLabel.text = subtitle.text
                    return
                }
            }
            self.subtitleLabel.text = ""
        }
    }
    
    private func parseWebVTT(_ contents: String) -> [(time: TimeInterval, text: String)] {
        var result: [(TimeInterval, String)] = []
        
        let blocks = contents.components(separatedBy: "\n\n")
        for block in blocks {
            let lines = block.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count >= 2 else { continue }
            
            let timeLine = lines.first(where: { $0.contains("-->") }) ?? ""
            let text = lines.drop { !$0.contains("-->") }.dropFirst().joined(separator: " ")
            
            let timeParts = timeLine.components(separatedBy: " --> ")
            if let startTime = parseTime(timeParts.first) {
                result.append((startTime, text))
            }
        }
        
        return result
    }
    
    private func parseTime(_ timeString: String?) -> TimeInterval? {
        guard let timeString = timeString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        
        let components = timeString.split(separator: ":").map { Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0 }
        if components.count == 3 {
            return components[0] * 3600 + components[1] * 60 + components[2]
        }
        return nil
    }
    
    private func showOverlayGif() {
        guard let path = Bundle.main.path(forResource: "overlay", ofType: "gif"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let animatedImage = UIImage.animatedImageWithSource(source) else {
            print("Failed to load overlay gif")
            return
        }
        
        overlayImageView.image = animatedImage
        overlayImageView.contentMode = .scaleAspectFill
        overlayImageView.alpha = 0.3
        overlayImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayImageView)
        
        NSLayoutConstraint.activate([
            overlayImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayImageView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // ✅ Ensure front-most views
        view.bringSubviewToFront(backButton)
        view.bringSubviewToFront(overlayLabel)
        view.bringSubviewToFront(exitGlassButton)
    }
    
    // MARK: 0.5, 1, 2, 3 X State
    
    private func setupButtonStack() {
        scaleButtonBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        
        let backgroundView = scaleButtonBackgroundView!
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.layer.cornerRadius = 20
        backgroundView.clipsToBounds = true
        backgroundView.alpha = 0
        backgroundView.isHidden = true
        view.addSubview(backgroundView)
        
        // Stack view setup...
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.contentView.addSubview(stackView)
        
        for value in values {
            let button = createButton(title: value)
            stackView.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            backgroundView.centerXAnchor.constraint(equalTo: placeButton.centerXAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: placeButton.topAnchor, constant: -32),
            stackView.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: backgroundView.contentView.bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: backgroundView.contentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: backgroundView.contentView.trailingAnchor, constant: -8)
        ])
        
        // Default select
        if stackView.arrangedSubviews.count > 1,
               let second = stackView.arrangedSubviews[1] as? UIButton {
                setActive(button: second)
                selectedButton = second
                selectedScaleValue = 1.0 // <- important to use the value for scaling
            }
    }
    
    private func createButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: buttonFontSize, weight: .bold)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        button.layer.borderWidth = 0.5
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        button.alpha = 0.3
        
        // Auto Layout
        button.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = button.widthAnchor.constraint(equalToConstant: inactiveSize)
        widthConstraint.isActive = true
        button.heightAnchor.constraint(equalTo: button.widthAnchor).isActive = true
        button.layer.cornerRadius = inactiveSize / 2
        
        // Save constraint for updates
        buttonWidthConstraints[button] = widthConstraint
        
        // Tap action
        button.addTarget(self, action: #selector(handleButtonTap(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func setActive(button: UIButton) {
        let baseTitle = button.title(for: .normal)?.replacingOccurrences(of: " x", with: "") ?? ""
        button.setTitle("\(baseTitle) x", for: .normal)
        button.setTitleColor(.yellow, for: .normal)
        button.alpha = 1.0
        
        if let constraint = buttonWidthConstraints[button] {
            constraint.constant = activeSize
            button.layer.cornerRadius = activeSize / 2
        }
    }
    
    private func setInactive(button: UIButton) {
        let baseTitle = button.title(for: .normal)?.replacingOccurrences(of: " x", with: "") ?? ""
        button.setTitle(baseTitle, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.alpha = 0.5
        
        if let constraint = buttonWidthConstraints[button] {
            constraint.constant = inactiveSize
            button.layer.cornerRadius = inactiveSize / 2
        }
    }
    
    private func updatePlaceButton(toHistory: Bool) {
        let imageName = toHistory ? "sejarah" : "place"
        let selector = toHistory ? #selector(historyButtonTapped) : #selector(placeObjectTapped)
        
        placeButton.setIcon(named: imageName)
        
        // Remove all previous targets
        placeButton.removeTarget(nil, action: nil, for: .allEvents)
        placeButton.addTarget(self, action: selector, for: .touchUpInside)
    }
    
    @objc private func scaleButtonTapped() {
        guard let entity = placedAnchor else { return }
        let scale = SIMD3<Float>(repeating: selectedScaleValue)
        entity.scale = scale
    }
    
    @objc private func handleButtonTap(_ sender: UIButton) {
        // Deactivate previous
        if let previous = selectedButton {
            setInactive(button: previous)
        }

        // Activate new
        setActive(button: sender)
        selectedButton = sender

        // Update selectedScaleValue
        if let title = sender.title(for: .normal)?.replacingOccurrences(of: " x", with: ""),
           let scale = Float(title) {
            selectedScaleValue = scale

            // Apply scale to the placed object
            if let entity = placedAnchor {
                let newScale = SIMD3<Float>(repeating: scale)
                entity.scale = newScale
            }
        }
    }

    
}

// MARK: Actions
private extension ARCamera {
    
    @objc private func placeObjectTapped() {
        guard !hasPlacedObject else { return }
        hasPlacedObject = true
        
        view.layoutIfNeeded()
        
        instructionLabel.isHidden = true
        
        deleteGlassButton.alpha = 0
        deleteGlassButton.isHidden = false
        
        
        scaleButtonBackgroundView.alpha = 0
        scaleButtonBackgroundView.isHidden = false
        
        
        UIView.animate(withDuration: 0.3) {
            self.deleteGlassButton.alpha = 1.0
            self.scaleButtonBackgroundView.alpha = 1.0
        }
        
        placeObject()
        
        updatePlaceButton(toHistory: true)
        
        // Reset scale UI to "1"
            if let stackView = scaleButtonBackgroundView?.contentView.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
                for case let button as UIButton in stackView.arrangedSubviews {
                    setInactive(button: button)

                    if button.title(for: .normal)?.contains("1") == true {
                        setActive(button: button)
                        selectedButton = button
                        selectedScaleValue = 1.0
                    }
                }
            }

            // Also apply scale = 1.0 to placed object
            placedAnchor?.scale = SIMD3<Float>(repeating: 1.0)
    }
    
    @objc private func deleteObjectTapped() {
        if let anchor = placedAnchor {
            anchor.removeFromParent()
            placedAnchor = nil
        }
        
        hasPlacedObject = false
        placeButton.isEnabled = true
        placeButton.alpha = 1.0
        showPreviewModel()
        overlayLabel.removeFromSuperview()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.deleteGlassButton.alpha = 0
            self.scaleButtonBackgroundView.alpha = 0
        }) { _ in
            self.deleteGlassButton.isHidden = true
            self.scaleButtonBackgroundView.isHidden = true
        }
        
        instructionLabel.isHidden = false
        updatePlaceButton(toHistory: false)
    }
    
    @objc private func historyButtonTapped() {
        glassOverlayVisible.toggle()
        
        // Set exit button visibility *immediately* (opposite of overlay)
        exitGlassButton.isHidden = glassOverlayVisible
        exitGlassButton.alpha = glassOverlayVisible ? 0.0 : 1.0
        
        // Animate overlay elements
        UIView.animate(withDuration: 0.3) {
            let overlayAlpha: CGFloat = self.glassOverlayVisible ? 1.0 : 0.0
            self.blurView?.alpha = overlayAlpha
            self.placeButton.alpha = overlayAlpha
        }
        
        if !glassOverlayVisible {
            showOverlayGif()
            view.bringSubviewToFront(exitGlassButton)
            setupSubtitleLabel()
            loadSubtitles()
            playAudio()
            
            // Hide extra buttons
            deleteGlassButton.alpha = 0
            deleteGlassButton.isHidden = true
            
            scaleButtonBackgroundView.alpha = 0
            scaleButtonBackgroundView.isHidden = true
            
        }
        
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
    
    @objc private func backButtonTapped() {
        let transition = CATransition()
        transition.duration = 0.4
        transition.type = .push
        transition.subtype = .fromLeft
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        
        dismiss(animated: false, completion: nil)
    }
    
    @objc private func exitButtonTapped() {
        // Stop player
        player?.pause()
        player = nil
        
        // Invalidate timer
        timer?.invalidate()
        timer = nil
        
        // Remove subtitle label and background
        subtitleLabel.removeFromSuperview()
        subtitleBackgroundView.removeFromSuperview()
        
        // Remove overlay GIF
        overlayImageView.removeFromSuperview()
        
        // Hide exit button
        exitGlassButton.isHidden = true
        exitGlassButton.alpha = 0.0
        
        glassOverlayVisible = true
        
        // Show overlay elements with animation
        UIView.animate(withDuration: 0.3) {
            self.blurView?.alpha = 1.0
            self.placeButton.alpha = 1.0
        }
        
        // Show extra buttons again
        deleteGlassButton.isHidden = false
        scaleButtonBackgroundView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.deleteGlassButton.alpha = 1.0
            self.scaleButtonBackgroundView.alpha = 1.0
            
        }
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
            modelEntity.setScale(SIMD3<Float>(repeating: 0.001), relativeTo: nil)
            anchor.addChild(modelEntity)
            showOverlayText()
        } catch {
            print("Failed to load model:", error)
        }
        
        instructionLabel.isHidden = true
    }
    
}

