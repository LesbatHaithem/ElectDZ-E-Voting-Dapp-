var Mayor = artifacts.require("Mayor");

module.exports = function(deployer) {
  const candidates = ["0x9814c22d2a81b0C24580a6aB1d8b04FE6b71a6e6", "0x26f73097E9066499EE608c2Aab4fDEB01e1fdab4", "0xbd6250efB0857F035Da25a6025b768c9eF2fF047"];
  const escrow = "0xC53d14eb163Dd81384552E3f329302cFE3e7e35b";
  const quorum = 3;
  const firstNames = ["Guessoum", "Lesbat", "Daoud"];
  const lastNames = ["Abdennour", "Haithem", "Yasser"];

  deployer.deploy(Mayor, candidates, escrow, quorum, firstNames, lastNames);
};