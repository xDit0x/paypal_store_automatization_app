import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var ocrChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "store_automatization_app/ocr",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "recognizeText" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let arguments = call.arguments as? [String: Any],
        let path = arguments["path"] as? String
      else {
        result(
          FlutterError(
            code: "bad_arguments",
            message: "Falta la ruta de la imagen.",
            details: nil
          )
        )
        return
      }

      self?.recognizeText(at: path, result: result)
    }
    ocrChannel = channel
  }

  /// Reconoce el texto de una imagen usando Apple Vision.
  ///
  /// Vision funciona tanto en dispositivo como en simulador (arm64), a
  /// diferencia de los frameworks de ML Kit, que no incluyen slice de
  /// simulador arm64.
  private func recognizeText(at path: String, result: @escaping FlutterResult) {
    guard
      let image = UIImage(contentsOfFile: path),
      let cgImage = image.cgImage
    else {
      result(
        FlutterError(
          code: "invalid_image",
          message: "No se pudo leer la imagen en \(path).",
          details: nil
        )
      )
      return
    }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["es-ES", "en-US"]

    let handler = VNImageRequestHandler(
      cgImage: cgImage,
      orientation: CGImagePropertyOrientation(image.imageOrientation),
      options: [:]
    )

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try handler.perform([request])
        let observations = request.results ?? []
        let text = observations
          .compactMap { $0.topCandidates(1).first?.string }
          .joined(separator: "\n")
        DispatchQueue.main.async { result(text) }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "ocr_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
  }
}

private extension CGImagePropertyOrientation {
  init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
