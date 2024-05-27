const fs = require('fs');
const path = require('path');
const Deputies = artifacts.require("Deputies");

module.exports = function(deployer) {
  const filePath = path.join(__dirname, 'deputies_candidates.json');
  const rawData = fs.readFileSync(filePath);
  const data = JSON.parse(rawData);

  const groupNames = data.groups.map(group => group.name);
  const groupPictures = data.groups.map(group => group.picture);
  const groupAddresses = data.groups.map(group => group.address);
  const escrow = data.escrow;
  const duration = data.duration;
  const candidates = data.candidates;

  deployer.deploy(Deputies, escrow, duration, groupNames, groupPictures, groupAddresses).then(async (instance) => {
    for (let i = 0; i < candidates.length; i++) {
      const candidate = candidates[i];
      await instance.addCandidateToGroup(
        candidate.groupAddress,
        candidate.address,
        candidate.firstName,
        candidate.lastName,
        candidate.imageUrl,
        candidate.gender,
        candidate.jobPosition,
        candidate.electoralDistrict,
        candidate.politicalAffiliation,
        candidate.age
      );
    }
  }).catch((error) => {
    console.error(error);
  });
};
