var Mayor = artifacts.require("Mayor");

module.exports = function(deployer) {
  const candidates = ["0x30d058e2FE577B8d112d62049A07d87cf49de6F5", "0xf2a7C3b3C9ee021f5F289b203E446e8De5EA681C", "0xa0c24043C1fbC8d0888C54A6f8765Edb8Ea06853"];
  const escrow = "0x5219A39D6f70B31d21cC89fD018B546d79Cc0608";
  const quorum = 2;
  const firstNames = ["Djouadi", "Lesbat", "Daoud"];
  const lastNames = ["Sohaib", "Haithem", "Yasser"];

  deployer.deploy(Mayor, candidates, escrow, quorum, firstNames, lastNames);
};