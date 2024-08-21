//
//  Constants.swift
//  HDBook
//
//  Created by hayesdavidson on 12/08/2024.
//

import Foundation

struct Constants {
    static let videoDirectory = "Videos"
    static let image360Directory = "360View"
    static let modelsDirectory = "3DModels"
    static let arImagesDirectory = "AR Images"
    static let superZoomDirectory = "SuperZoom"
    static let filmsDirectory = "Films"
    
    static let videoExtension = "mp4"
    static let image360Extension = "jpg"
    static let modelExtension = "usdz"
    static let superZoomExtension = "jpg"
    static let filmExtension = "mp4"
    
    static let videoSuffix = "_CIN"
    static let image360Suffix = "_360"
    static let modelSuffix = "_ARM"
    static let superZoomSuffix = "_SPZ"
    static let filmSuffix = "_FLM"
    static let webSuffix = "_WEB"
    
    static let assetTypeVideo = "video"
    static let assetTypeImage360 = "image360"
    static let assetTypeModel = "model"
    static let assetTypeSuperZoom = "superZoom"
    static let assetTypeFilm = "film"
    static let assetTypeWeb = "web"
    
    
    enum WebAssets: String {
        case langtownhouse = "Langtownhouse_WEB-18"
        case hdStories = "HDStories_WEB-18"
        
        var url: URL? {
            switch self {
            case .langtownhouse:
                return URL(string: "https://app.envisionvr.net/?intent=view/HY01")
            case .hdStories:
                return URL(string: "https://www.hayesdavidson.com/stories/planning-images-for-a-sensitive-project-in-a-heritage-setting")
            }
        }
    }
}

