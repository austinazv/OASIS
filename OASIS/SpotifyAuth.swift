//
//  SpotifyAuth.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/3/25.
//

import Foundation

struct SpotifyAuth {
    static let clientID = "6b54a209133d4ac7a7c15ee099bbeee8"
    static let clientSecret = "ecf461f0dd1b40ecb59a6a118f623a9a"
    static let redirectURI = "OASIS://callback/spotify"
    static let scope = "playlist-modify-public playlist-modify-private"
    
    static var authURL: URL {
        let base = "https://accounts.spotify.com/authorize"
        let responseType = "code"
        let encodedRedirectURI = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        return URL(string: "\(base)?client_id=\(clientID)&response_type=\(responseType)&redirect_uri=\(encodedRedirectURI)&scope=\(scope)")!
    }
}
