async function createEvent(
  contract,
  name,
  description,
  targetAmount,
  endDate,
  category,
  fromAccount
) {
  return await contract.methods
    .createEvent(name, description, targetAmount, endDate, category)
    .send({ from: fromAccount });
}

async function addMilestone(
  contract,
  eventId,
  milestoneName,
  description,
  amount,
  endDate,
  fromAccount
) {
  return await contract.methods
    .addMilestone(eventId, milestoneName, description, amount, endDate)
    .send({ from: fromAccount });
}

async function markMilestoneAsCompleted(
  contract,
  eventId,
  milestoneId,
  spendedAmount,
  fromAccount
) {
  return await contract.methods
    .markMilestoneAsCompleted(eventId, milestoneId, spendedAmount)
    .send({ from: fromAccount });
}

async function getEventDetails(contract, eventId) {
  return await contract.methods.getEventDetails(eventId).call({ gas: 5000000 });
}

module.exports = {
  createEvent,
  addMilestone,
  markMilestoneAsCompleted,
  getEventDetails,
};
