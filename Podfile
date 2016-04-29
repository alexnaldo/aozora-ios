source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

inhibit_all_warnings!
use_frameworks!

def common_pods
    pod 'Alamofire', '~> 2.0'
    pod 'TTTAttributedLabel', '~> 1.13.4'
    pod 'MMWormhole', '~> 2.0.0'
    pod 'FLAnimatedImage', '~> 1.0'
    pod 'PINRemoteImage', '~> 2.0'
end

target 'ANCommonKit' do
    common_pods
end

target 'AozoraWatching' do
    common_pods
end

target 'AnimeTrakrWatching' do
    common_pods
end

def app_pods
    plugin 'cocoapods-keys', {
        :keys => [
        'ParseApplicationId',
        'ParseClientKey',
        'TrakrV1ApiKey',
        'TrakrV2ClientId',
        'TraktV2ClientSecret',
        'AnilistClientID',
        'AnilistClientSecret',
        'ParseServerURL',
        'FlurryAPIKey'
        ]
    }

    common_pods
    pod 'JTSImageViewController', '~> 1.3'
    pod 'FontAwesome+iOS'
    pod 'Shimmer'
    pod 'XLPagerTabStrip', '~> 1.1.1'
    pod 'XCDYouTubeKit', '~> 2.4.1'
    pod 'RMStore', '~> 0.7'
    pod 'iRate', '~> 1.11.4'
    pod 'HCSStarRatingView'
    pod 'RSKImageCropper'
    pod 'FLAnimatedImage', '~> 1.0'
    pod 'CRToast', '~> 0.0.7'
    pod 'uservoice-iphone-sdk', '~> 3.2'
    pod 'Flurry-iOS-SDK', '~> 7.6'
    pod 'Toucan'
    pod 'DZNEmptyDataSet'
    pod 'NYTPhotoViewer', '~> 1.1.0'
    pod 'YoutubeSourceParserKit'
end


target 'Aozora' do
    app_pods
end

target 'AnimeTrakr' do
    app_pods
end

