module.exports = {

  networks: {
     development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "5777",
      from: "0xFaF7440a5935a1FEA023a677232E6C70AB35Dc82", // Specify the deployer account address

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
