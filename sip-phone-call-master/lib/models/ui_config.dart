class UiConfig {
  String logoAssetName;
  String effectRingingLottie;
  String iconTransferCall;
  String iconUnHoldCall;

  UiConfig({
    required this.logoAssetName,
    required this.iconTransferCall,
    required this.iconUnHoldCall,
    this.effectRingingLottie = 'packages/sip_phone_call/assets/json/ripple_video_call.json',
  });
}
