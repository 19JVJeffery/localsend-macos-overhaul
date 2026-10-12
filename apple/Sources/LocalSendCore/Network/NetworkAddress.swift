import Foundation
import Network

public struct LocalNetworkInterface: Sendable {
    public let name: String
    public let address: String
    public let netmask: String
    public let broadcast: String?
}

public enum NetworkAddressHelper {
    /// Returns active IPv4 network interface addresses on the device (e.g. en0, en1, etc.)
    public static func getLocalIPv4Addresses() -> [LocalNetworkInterface] {
        var interfaces: [LocalNetworkInterface] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return []
        }
        defer { freeifaddrs(ifaddr) }

        var ptr = Optional(firstAddr)
        while let cursor = ptr {
            let interface = cursor.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                // Filter out loopback
                let flags = Int32(interface.ifa_flags)
                let isLoopback = (flags & IFF_LOOPBACK) != 0
                let isUp = (flags & IFF_UP) != 0
                let isRunning = (flags & IFF_RUNNING) != 0

                if isUp && isRunning && !isLoopback {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, 0, NI_NUMERICHOST) == 0 {
                        let address = String(cString: hostname)

                        var netmaskStr = ""
                        if let netmask = interface.ifa_netmask {
                            var maskname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            if getnameinfo(netmask, socklen_t(netmask.pointee.sa_len),
                                           &maskname, socklen_t(maskname.count),
                                           nil, 0, NI_NUMERICHOST) == 0 {
                                netmaskStr = String(cString: maskname)
                            }
                        }

                        var broadcastStr: String?
                        if let broad = interface.ifa_dstaddr {
                            var bname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            if getnameinfo(broad, socklen_t(broad.pointee.sa_len),
                                           &bname, socklen_t(bname.count),
                                           nil, 0, NI_NUMERICHOST) == 0 {
                                broadcastStr = String(cString: bname)
                            }
                        }

                        interfaces.append(LocalNetworkInterface(
                            name: name,
                            address: address,
                            netmask: netmaskStr,
                            broadcast: broadcastStr
                        ))
                    }
                }
            }
            ptr = cursor.pointee.ifa_next
        }
        return interfaces
    }
}
