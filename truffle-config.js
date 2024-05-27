module.exports = {

  networks: {
     development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "5777",
      from: "0xE5d652ba62b388b2B89484eF956Bf2963c5d5a6E", // Specify the deployer account address

     },
  },
  compilers: {
    solc: {
        version: "0.8.1",
        optimizer: {
          enabled: false,
          runs: 200
        },
        evmVersion: "byzantium"
      // }
    }
  },
};
