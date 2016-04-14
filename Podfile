source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

plugin 'cocoapods-keys', {
    :project => 'Aozora',
    :keys => [
    'ParseApplicationId',
    'TrakrV1ApiKey',
    'TrakrV2ClientId',
    'TraktV2ClientSecret',
    'AnilistClientID',
    'AnilistClientSecret',
    'ParseServerURL'
    ]
}

inhibit_all_warnings!
use_frameworks!

def common_pods
    pod 'Alamofire', '~> 2.0'
    pod 'SDWebImage', '~> 3.7.2'
    pod 'TTTAttributedLabel', '~> 1.13.4'
    pod 'MMWormhole', '~> 2.0.0'
    pod 'FLAnimatedImage', '~> 1.0'

end

target 'Aozora' do
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
end


target 'ANCommonKit' do
    common_pods
end
