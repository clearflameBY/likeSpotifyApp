//
//  playlistModel.swift
//  akaSpotifyApp
//
//  Created by Илья Степаненко on 15.11.25.
//

import FirebaseFirestore

struct Playlist: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String?
    var tracksIDs: [String]
    var coverArtURL: String?
}
