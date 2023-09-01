async function createEvent(
  contract,
  name,
  description,
  targetAmount,
  fromAccount
) {
  return await contract.methods
    .createEvent(name, description, targetAmount)
    .send({ from: fromAccount });
}

async function addMilestone(
  contract,
  eventId,
  description,
  amount,
  fromAccount
) {
  return await contract.methods
    .addMilestone(eventId, description, amount)
    .send({ from: fromAccount });
}

async function markMilestoneAsCompleted(
  contract,
  eventId,
  milestoneId,
  fromAccount
) {
  return await contract.methods
    .markMilestoneAsCompleted(eventId, milestoneId)
    .send({ from: fromAccount });
}

async function getEventDetails(contract, eventId) {
  return await contract.methods.getEventDetails(eventId).call();
}
