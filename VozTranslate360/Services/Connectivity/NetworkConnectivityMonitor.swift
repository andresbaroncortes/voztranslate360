//
//  NetworkConnectivityMonitor.swift
//  VozTranslate 360 — Atlas Business
//
//  Estado real de la conexión con Network (NWPathMonitor).
//  No envía datos a ningún servidor: solo observa la ruta de red del iPhone.
//

import Foundation
import Network
import Observation

@MainActor
@Observable
final class NetworkConnectivityMonitor: ConnectivityMonitoring {

    private(set) var isConnected = true
    private(set) var isExpensive = false
    /// «Datos reducidos» activado por el usuario.
    private(set) var isConstrained = false

    @ObservationIgnored private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let expensive = path.isExpensive
            let constrained = path.isConstrained
            Task { @MainActor in
                self?.apply(connected: connected, expensive: expensive, constrained: constrained)
            }
        }
        monitor.start(queue: DispatchQueue(label: "com.atlasbusiness.VozTranslate360.network"))
    }

    private func apply(connected: Bool, expensive: Bool, constrained: Bool) {
        if isConnected != connected { isConnected = connected }
        if isExpensive != expensive { isExpensive = expensive }
        if isConstrained != constrained { isConstrained = constrained }
    }
}
