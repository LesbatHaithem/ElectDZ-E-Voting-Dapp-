module.exports = {

  networks: {
     development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "5777",
      from: "0x636fA8e15B8D61345268ed45bF4b3d65F20Cbc37", // Specify the deployer account address

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
