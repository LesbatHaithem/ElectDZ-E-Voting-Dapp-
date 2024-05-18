module.exports = {

  networks: {
     development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "5777",
      from: "0x23b3D40fE6E40449720a0e6F9868b4D14b055ED5", // Specify the deployer account address

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
