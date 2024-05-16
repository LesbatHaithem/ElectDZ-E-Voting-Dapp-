var Mayor = artifacts.require("Mayor");
module.exports = function(deployer) {
    deployer.deploy(Mayor, ["0x7896a37E93A13a23c2e686317ee57e2D65f10859", "0x31DCCd22151132293C9D1823A8649e5aD95bB268" ], "0x147cEe32C26dfAe9b70C4604ec222365933ee773", 1);
};