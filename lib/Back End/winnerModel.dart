class WinnerModel {
  String? addr;
  BigInt? souls;
  BigInt? votes;

  WinnerModel(String addr, BigInt souls, BigInt votes) {
    this.addr = addr;
    this.souls = souls;
    this.votes = votes;
  }

  String soulsUnit(){
    double wei = souls!.toDouble();
    if (wei >= 10000000000000000){
      return (wei/1000000000000000000).toString() + " ETH";
    } else if (wei >= 10000000){
      return (wei/1000000000).toString() + " GWEI";
    } else {
      return wei.toString() + " WEI";
    }
  }
}