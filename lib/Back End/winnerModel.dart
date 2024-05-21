class WinnerModel {
  String? groupAddr;
  BigInt? votes;
  String? groupName;
  String? pictureUrl;
  double? percentage;

  WinnerModel(String groupAddr, BigInt votes, String groupName, String pictureUrl, double percentage) {
    this.groupAddr = groupAddr;
    this.votes = votes;
    this.groupName = groupName;
    this.pictureUrl = pictureUrl;
    this.percentage = percentage;
  }
}
