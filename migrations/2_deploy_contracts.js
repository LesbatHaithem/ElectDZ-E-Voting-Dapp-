var Mayor = artifacts.require("Mayor");

module.exports = function(deployer) {
  const groupNames = [" Front de Libération Nationale", "RND", "Group 3"];
  const groupPictures = [
    "https://white-high-quokka-246.mypinata.cloud/ipfs/QmYxRmfiqaRDHYGxtnMN5zwE4c1M5PjwgRaWNYQbzdr7tq",
    "https://white-high-quokka-246.mypinata.cloud/ipfs/QmTT67kkk4F4KWbHojGH7zM7qTuv8tpWhAgeviyLG4UhW3",
    "https://white-high-quokka-246.mypinata.cloud/ipfs/QmQ6LtHJhCiwvkrtd22Tx9FNnYufsztxEfT1RCrk9vSS2f",
  ];

  const groupAddresses = [
    "0x2b791c9663960043F05F9fe525bc6F6e1480fC4D",
    "0x80a9884Ced71562c94D72e3576CE38D5AFd24c8B",
    "0x00458aabEDBd93b5d057625BB6880f77594effb9"
  ];

  const escrow = "0x9e31CDbC17738fb0471093d44DebB8760f554379";
  const quorum = 1;

  deployer.deploy(Mayor, escrow, quorum, groupNames, groupPictures, groupAddresses).then(async (instance) => {
    const candidates = [
      {
        address: "0xB4b7910E3BDd3b2a3d37AD3a7E16988caF6298d2",
        firstName: "Guessoum",
        lastName: "Abdennour",
        imageUrl: "https://gateway.pinata.cloud/ipfs/QmX6zGVETnu7SKdy6GahWV3bSFBZjTB2RG1MCJmBYrky8S",
        groupAddress: "0x2b791c9663960043F05F9fe525bc6F6e1480fC4D"
      },
      {
        address: "0x9B3878B49ED31BE079e722FbF49f7D75a376871d",
        firstName: "Lesbat",
        lastName: "Haithem",
        imageUrl: "https://gateway.pinata.cloud/ipfs/QmVJu6zhRBHNHNeC8ZVmXFBUxKcRkPfKRhxNhoRNdVH1c9",
        groupAddress: "0x2b791c9663960043F05F9fe525bc6F6e1480fC4D"
      },
      {
              address: "0x02a5895047EC40a62183F50657fb362C57e5e83d",
              firstName: "Boudraa",
              lastName: "Soufiane",
              imageUrl: "https://white-high-quokka-246.mypinata.cloud/ipfs/QmNuiSq99N1UrAiPoAqWpmzuqXfVdbKxgrpqJXBSF89L4r",
              groupAddress: "0x2b791c9663960043F05F9fe525bc6F6e1480fC4D"
            },
      {
        address: "0x25D11Aa76f7AB02c1B5ee20986441A1E7E4983CB",
        firstName: "Daoud",
        lastName: "Yasser",
        imageUrl: "https://gateway.pinata.cloud/ipfs/QmUMr4z2HyymMxJL4PvzXTJ87uePTT3LKDHdTntiPktAMM",
        groupAddress: "0x00458aabEDBd93b5d057625BB6880f77594effb9"
      }
    ];

    for (let i = 0; i < candidates.length; i++) {
      const candidate = candidates[i];
      await instance.addCandidateToGroup(
        candidate.groupAddress,
        candidate.address,
        candidate.firstName,
        candidate.lastName,
        candidate.imageUrl
      );
    }
  }).catch((error) => {
    console.error(error);
  });
};
