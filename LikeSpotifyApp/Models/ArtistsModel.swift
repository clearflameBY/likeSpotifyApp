//
//  ArtistsModel.swift
//  LikeSpotifyApp
//
//  Created by Илья Степаненко on 03.12.2025.
//
import FirebaseFirestore

struct Artists: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var info: String
    var photo: String
}
