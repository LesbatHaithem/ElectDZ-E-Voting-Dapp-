var Mayor = artifacts.require("Mayor");

module.exports = function(deployer) {
  const candidates = ["0x76b56A6Ef22EFE0D9605C0C173f05E61ee1A24fe", "0xAC5979cd08726FD5155808D3160D9ee595723C4E", "0xb315386af25eAb928AE65F15d51bEf568185E6a1"];
  const escrow = "0xF5D131d65A57632b18F7B538f2E40e67AAA2b585";
  const quorum = 3;
  const firstNames = ["Guessoum", "Lesbat", "Daoud"];
  const lastNames = ["Abdennour", "Haithem", "Yasser"];

  deployer.deploy(Mayor, candidates, escrow, quorum, firstNames, lastNames);
};