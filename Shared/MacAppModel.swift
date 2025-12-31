//
//  MacApp.swift
//  FinderPlus
//
//  Created by 0x400 on 2025/11/7.
//
import Foundation

import SwiftUI

struct MacApp: Identifiable, Equatable ,Hashable{
    var id = UUID()
    let name: String
    let bundleID: String
    let version: String
    let path: URL
    let icon:NSImage
    var keywords: String { "\(name) \(bundleID) \(version)" }
}
