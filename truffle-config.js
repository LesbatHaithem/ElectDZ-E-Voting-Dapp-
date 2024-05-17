module.exports = {

  networks: {
     development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "5777",
      from: "0x8D2e594e3E9CF9A4037161a8a3289Fa378eF9F0C", // Specify the deployer account address

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
