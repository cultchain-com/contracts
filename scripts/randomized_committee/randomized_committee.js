async function formCommittee(contract, size, fromAccount) {
  return await contract.methods.formCommittee(size).send({ from: fromAccount });
}

async function getMyDecisions(contract, fromAccount) {
  return await contract.methods.GetMyDecisions().call({ from: fromAccount });
}

async function isCommitteeMember(contract, committeeId, member) {
  return await contract.methods.isCommitteeMember(committeeId, member).call();
}

async function recordDecision(
  contract,
  committeeId,
  decision,
  feedback,
  fromAccount
) {
  return await contract.methods
    .recordDecision(committeeId, decision, feedback)
    .send({ from: fromAccount });
}

async function getValidatorCount(contract) {
  return await contract.methods.getValidatorCount().call();
}

async function getCommitteeDecision(contract, committeeId) {
  return await contract.methods.getCommitteeDecision(committeeId).call();
}

async function addValidator(contract, newValidator, fromAccount) {
  return await contract.methods
    .addValidator(newValidator)
    .send({ from: fromAccount });
}

async function removeValidator(contract, validatorToRemove, fromAccount) {
  return await contract.methods
    .removeValidator(validatorToRemove)
    .send({ from: fromAccount });
}

async function getValidatorProfile(contract, validator) {
  return await contract.methods.getValidatorProfile(validator).call();
}

module.exports = {
  formCommittee,
  getMyDecisions,
  isCommitteeMember,
  recordDecision,
  getValidatorCount,
  getCommitteeDecision,
  getValidatorProfile,
  removeValidator,
  addValidator,
};
