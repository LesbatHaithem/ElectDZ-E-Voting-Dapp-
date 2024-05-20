class WinnerModel {
  String? groupAddr;
  BigInt? votes;
  String? groupName;
  String? pictureUrl;

  WinnerModel(String groupAddr, BigInt votes, String groupName, String pictureUrl) {
    this.groupAddr = groupAddr;
    this.votes = votes;
    this.groupName = groupName;
    this.pictureUrl = pictureUrl;
  }
}
