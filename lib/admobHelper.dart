import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:youniyou/config/env.dart';

// デバッグではenvをdevにしておく
String env = 'development';
// String env = getEnv('ENV');
//プラットホームごとのテスト広告IDを取得するメソッド
String getTestAdBannerUnitId() {
  String testBannerUnitId = "";

  // Android のとき
  if (Platform.isAndroid) {
    if (env == 'development') {
      // テスト
      testBannerUnitId = "ca-app-pub-3940256099942544/6300978111";
    } else {
      // 本番
      testBannerUnitId = "ca-app-pub-1568606156833955/2381635966";
    }
  }
  // iOSのとき
  else if (Platform.isIOS) {
    if (env == 'development') {
      // テスト
      testBannerUnitId = "ca-app-pub-3940256099942544/2934735716";
    } else {
      // 本番
      testBannerUnitId = "ca-app-pub-1568606156833955/6428692187";
    }
  }
  return testBannerUnitId;
}

//プラットホームごとの広告IDを取得するメソッド
String getAdBannerUnitId() {
  String bannerUnitId = "";
  if (Platform.isAndroid) {
    // Android のとき
    bannerUnitId = "ca-app-pub-";
  } else if (Platform.isIOS) {
    // iOSのとき
    bannerUnitId = "ca-app-pub-";
  }
  return bannerUnitId;
}

class AdmobHelper implements RewardedAdLoadCallback, FullScreenContentCallback {
  // インタースティシャル広告のインスタンス
  InterstitialAd? _interstitialAd;

  //初期化処理
  static initialization() {
    if (MobileAds.instance == null) {
      MobileAds.instance.initialize();
    }
  }

  // インタースティシャル広告のID定義
  String getInterstitialAd() {
    if (env == 'development') {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Androidのテスト用広告ユニットID
          : 'ca-app-pub-3940256099942544/4411468910'; // iOSのテスト用広告ユニットID
    } else {
      // ここ適当だから実際のコード入れる
      return Platform.isAndroid
          ? 'ca-app-pub-1568606156833955/9463786776' // Androidの本番用広告ユニットID
          : 'ca-app-pub-1568606156833955/7779170011'; // iOSの本番用広告ユニットID
    }
  }

  // インタースティシャル広告のロード
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: getInterstitialAd(),
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  // インタースティシャル広告の表示
  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd?.show();
    } else {
      print('Warning: attempt to show interstitial before loaded.');
    }
  }

  //バナー広告を初期化する処理
  static BannerAd getBannerAd() {
    BannerAd bAd = BannerAd(
      adUnitId: getTestAdBannerUnitId(),
      // size: AdSize.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (Ad ad) => print('Ad loaded.'),
        // Called when an ad request failed.
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          // Dispose the ad here to free resources.
          ad.dispose();
          print('Ad failed to load: $error');
        },
        onAdClosed: (Ad ad) {
          print('ad dispose.');
          ad.dispose();
        },
      ),
    );
    return bAd;
  }

  //ラージサイズのバナー広告を初期化する処理
  static BannerAd getLargeBannerAd() {
    BannerAd bAd = BannerAd(
      adUnitId: getTestAdBannerUnitId(),
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (Ad ad) => print('Ad loaded.'),
        // Called when an ad request failed.
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          // Dispose the ad here to free resources.
          ad.dispose();
          print('Ad failed to load: $error');
        },
        onAdClosed: (Ad ad) {
          print('ad dispose.');
          ad.dispose();
        },
      ),
    );
    return bAd;
  }

  //リワード広告を初期化する処理
  RewardedAd? _rewardedAd; // 広告オブジェクト

  // 広告のロード処理
  void loadRewardedAd() {
    RewardedAd.load(
      // テスト
      adUnitId: Platform.isAndroid ? 'ca-app-pub-3940256099942544/5224354917' : "ca-app-pub-3940256099942544/1712485313",
      // 本番(iOSでは設定しない)
      // adUnitId: Platform.isAndroid
      //     ? 'ca-app-pub-1568606156833955/7823645898'
      //     : "ca-app-pub-3940256099942544/1712485313",

      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad; // 広告オブジェクトを保存
        },
        onAdFailedToLoad: (error) {
          print('Ad failed to load: $error');
        },
      ),
    );
  }

  // 広告の表示処理
  void showRewardedAd() {
    // 広告が表示されたときの処理
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('Ad showed fullscreen content.');
      },
      // 広告が閉じられたときの処理
      onAdDismissedFullScreenContent: (ad) {
        print('Ad dismissed fullscreen content.');
        ad.dispose();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Ad failed to show fullscreen content: $error');
        ad.dispose();
        loadRewardedAd();
      },
    );

    _rewardedAd?.setImmersiveMode(true);
    _rewardedAd?.show(
      // リワード広告再生時の処理
      onUserEarnedReward: (ad, reward) {
        print('User earned reward: ${reward.amount} ${reward.type}');
        // TODO: 報酬を与える処理を追加
      },
    );
  }

  // リワード広告のロードが成功した場合のコールバック
  @override
  void onRewardedAdLoaded(RewardedAd ad) {
    _rewardedAd = ad;
  }

  // リワード広告のロードが失敗した場合のコールバック
  @override
  void onRewardedAdFailedToLoad(LoadAdError error) {
    print('Rewarded ad failed to load: $error');
  }

  // リワード広告が閉じられた場合のコールバック
  @override
  void onRewardedAdDismissed(RewardedAd ad) {
    ad.dispose();
    loadRewardedAd();
  }

  // リワード広告が表示できなかった場合のコールバック
  @override
  void onRewardedAdFailedToShow(RewardedAd ad, AdError error) {
    ad.dispose();
    loadRewardedAd();
  }

  // 報酬広告が開いたときに実行されるコールバック
  @override
  void onRewardedAdOpened(RewardedAd ad) {
    print('Rewarded ad opened.');
  }

  // ユーザーが報酬を獲得したときに実行されるコールバック
  @override
  void onUserEarnedReward(RewardedAd ad, RewardItem reward) {
    print('User earned reward: ${reward.amount} ${reward.type}');
  }

  // 広告がクリックされたときに実行されるコールバック
  @override
  // TODO: implement onAdClicked
  GenericAdEventCallback? get onAdClicked => throw UnimplementedError();

  // フルスクリーン広告が閉じられたときに実行されるコールバック
  @override
  // TODO: implement onAdDismissedFullScreenContent
  GenericAdEventCallback? get onAdDismissedFullScreenContent => throw UnimplementedError();

  // 広告の読み込みに失敗したときに実行されるコールバック
  @override
  // TODO: implement onAdFailedToLoad
  FullScreenAdLoadErrorCallback get onAdFailedToLoad => throw UnimplementedError();

  // フルスクリーン広告の表示に失敗したときに実行されるコールバック
  @override
  // TODO: implement onAdFailedToShowFullScreenContent
  void Function(dynamic ad, AdError error)? get onAdFailedToShowFullScreenContent => throw UnimplementedError();

  // 広告が表示されたときに実行されるコールバック
  @override
  // TODO: implement onAdImpression
  GenericAdEventCallback? get onAdImpression => throw UnimplementedError();

  // 広告が読み込まれたときに実行されるコールバック
  @override
  // TODO: implement onAdLoaded
  GenericAdEventCallback<RewardedAd> get onAdLoaded => throw UnimplementedError();

  // フルスクリーン広告が表示されたときに実行されるコールバック
  @override
  // TODO: implement onAdShowedFullScreenContent
  GenericAdEventCallback? get onAdShowedFullScreenContent => throw UnimplementedError();

  // フルスクリーン広告が閉じられる直前に実行されるコールバック
  @override
  // TODO: implement onAdWillDismissFullScreenContent
  GenericAdEventCallback? get onAdWillDismissFullScreenContent => throw UnimplementedError();
}
