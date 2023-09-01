async function grantRole(web3, contract, role, account, fromAccount) {
  return await contract.methods
    .grantRole(web3.utils.keccak256(role), account)
    .send({ from: fromAccount });
}

async function revokeRole(web3, contract, role, account, fromAccount) {
  return await contract.methods
    .revokeRole(web3.utils.keccak256(role), account)
    .send({ from: fromAccount });
}

async function hasRole(web3, contract, role, account) {
  return await contract.methods
    .hasRole(web3.utils.keccak256(role), account)
    .call();
}

module.exports = {
  grantRole,
  revokeRole,
  hasRole,
};
