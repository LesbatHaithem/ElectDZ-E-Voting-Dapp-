class WinnerModel {
  String? addr;
  BigInt? votes;
  String? firstName;
  String? lastName;

  WinnerModel(String addr, BigInt votes, String firstName , String lastName ) {
    this.addr = addr;
    this.votes = votes;
    this.firstName = firstName;
    this.lastName = lastName;
  }
}