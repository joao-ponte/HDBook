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
        case southDowntow = "Story_p41_Liveable South Downtown_WEB-18"
        case memorialLearningCentre = "Story_p317_Holocaust Memorial & Learning Centre_WEB-18"
        case tintagelCastleFootbridge = "Story_p549_Tintagel Castle Footbridge_WEB-18"
        case oneAndOnlyKeaIsland = "Story_p581_One&Only Kéa Island_WEB-18"
        case kaoLaAmani = "Story_p609_Kao La Amani_WEB-18"
        case thirdSpace = "Story_p617_Third Space_WEB-18"
        
        
        //https://www.hayesdavidson.com/stories/an-early-stage-illustrative-concept-to-support-a-revitalised-seattle
        //https://app.envisionvr.net/?intent=view/HY01
        var url: URL? {
            switch self {
            case .southDowntow:
                return URL(string: "https://app.envisionvr.net/?intent=view/HY01")
            case .memorialLearningCentre:
                return URL(string: "https://www.hayesdavidson.com/stories/planning-images-for-a-sensitive-project-in-a-heritage-setting")
            case .tintagelCastleFootbridge:
                return URL(string: "https://www.hayesdavidson.com/stories/bespoke-lighting-to-stand-out-from-the-competition")
            case .oneAndOnlyKeaIsland:
                return URL(string: "https://www.hayesdavidson.com/stories/from-planning-to-marketing-images-for-an-idyllic-island-getaway")
            case .kaoLaAmani:
                return URL(string: "https://www.hayesdavidson.com/stories/a-storybook-aesthetic-to-engage-children-in-their-school-design")
            case .thirdSpace:
                return URL(string: "https://www.hayesdavidson.com/stories/a-creative-partnership-unlocks-innovation-for-the-cultural-sector")
            }
        }
    }
}

