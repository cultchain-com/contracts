require("dotenv").config();
const Web3 = require("web3");
const HDWalletProvider = require("@truffle/hdwallet-provider");

process.on("unhandledRejection", (reason, promise) => {
  console.error("Unhandled Rejection at:", promise, "reason:", reason);
});

const CommitteeType = {
  0: "Event",
  1: "Milestone",
  2: "Validator",
};

const EventCategory = {
  Health: 0,
  Education: 1,
  Environment: 2,
  DisasterRelief: 3,
  AnimalWelfare: 4,
  Others: 5,
};

const CategoryList = {
  0: "Health",
  1: "Education",
  2: "Environment",
  3: "DisasterRelief",
  4: "AnimalWelfare",
  5: "Others",
};

const EventMilestoneStatus = {
  0: "Pending",
  1: "Approved",
  2: "Rejected",
  3: "NotStartedYet",
};

const randomizedCommitteeArtifacts = require("../artifacts/contracts/RandomizedCommittee.sol/RandomizedCommittee.json");
const charityEventsArtifacts = require("../artifacts/contracts/CharityEvent.sol/CharityEvent.json");

const randomizedCommitteeABI = randomizedCommitteeArtifacts.abi;
const charityEventsABI = charityEventsArtifacts.abi;

const randomizedCommitteeAddress = "0x3dDEdded14c2Bf429EA0cf9F31764F9aa14a6AFc";
const charityEventsAddress = "0x1C2622cb0b50A33b1d866065340EB7091EC6954b";

const provider = new HDWalletProvider(
  "8eb2e13f92e850fb487aa6ff5aa786818d440395115ba91baf34e33d6722ac24",
  "https://rpc-mumbai.maticvigil.com/"
);
const web3 = new Web3(provider);

let validators = [
  "0x13DC81736DdE2c2b788c7634610e549d5fd0C294",
  "0x056D87A67455C9E4400FE3945c739E5f50Ec7f1E",
  "0xD05f036B42e10771Ff35F184E4A4C68B9100C836",
  "0x3da2581ad70D98a45ebE7D3A51D821ddDe640432",
  "0xa25994d6F8404aFFD42Ae5918d9e2D704e06E20A",
];

const addValidator = async (validatorAddress) => {
  const accounts = await web3.eth.getAccounts();
  const ownerAccount = accounts[0];

  const randomizedCommitteeContract = new web3.eth.Contract(
    randomizedCommitteeABI,
    randomizedCommitteeAddress
  );

  try {
    const tx = await randomizedCommitteeContract.methods
      .addValidator(validatorAddress)
      .send({ from: ownerAccount });
    console.log(
      "Validator added successfully. Transaction hash:",
      tx.transactionHash
    );
  } catch (error) {
    console.error("Error adding validator:", error);
  }
};

const getMilestoneDetail = async (eventId, charityEventsContract) => {
  try {
    const milestoneDetails = await charityEventsContract.methods
      .getMilestonesForEvent(eventId)
      .call();

    return milestoneDetails;
  } catch (error) {
    console.error("Error fetching milestone details:", error);
    throw error;
  }
};

const getUserOngoingDecisions = async (userAddress) => {
  try {
    const randomizedCommitteeContract = new web3.eth.Contract(
      randomizedCommitteeABI,
      randomizedCommitteeAddress
    );

    const charityEventsContract = new web3.eth.Contract(
      charityEventsABI,
      charityEventsAddress
    );

    const ongoingDecisions = await randomizedCommitteeContract.methods
      .getUserOngoingDecisions(userAddress)
      .call();

    const committeesDetail = await Promise.all(
      ongoingDecisions.map(async (committeeId) => {
        const committeeDetail = await randomizedCommitteeContract.methods
          .committees(committeeId)
          .call();

        // Remove redundant numbered properties
        for (let i = 0; i <= 5; i++) {
          // Assuming there are properties from '0' to '5'
          delete committeeDetail[i.toString()];
        }

        console.log(committeeDetail.committeeTypeId);

        if (CommitteeType[committeeDetail.committeeType] === "Event") {
          const { eventDetails } = await getEventDetail(
            committeeDetail.committeeTypeId,
            charityEventsContract
          );
          committeeDetail.proposalDetail = eventDetails;
        } else if (
          CommitteeType[committeeDetail.committeeType] === "Milestone"
        ) {
          const milestoneDetail = await getMilestoneDetail(
            committeeDetail.committeeTypeId,
            charityEventsContract
          );
          committeeDetail.proposalDetail = milestoneDetail;
        }

        committeeDetail.committeeType =
          CommitteeType[committeeDetail.committeeType];

        return committeeDetail;
      })
    );

    console.log(
      "Ongoing Decisions for Address",
      userAddress,
      ":",
      committeesDetail
    );
    return committeesDetail;
  } catch (error) {
    console.error("Error fetching ongoing decisions:", error);
    throw error;
  }
};

const assignValidatorRole = async (address) => {
  const accounts = await web3.eth.getAccounts();
  const ownerAccount = accounts[0];

  const randomizedCommitteeContract = new web3.eth.Contract(
    randomizedCommitteeABI,
    randomizedCommitteeAddress
  );

  try {
    const tx = await randomizedCommitteeContract.methods
      .grantValidatorRole(address)
      .send({ from: ownerAccount });
    console.log(
      "Validator Access Granted successfully. Transaction hash:",
      tx.transactionHash
    );
  } catch (error) {
    console.error("Error creating event:", error);
  }
};

const createEvent = async (
  eventName,
  eventDescription,
  targetAmount,
  endDate,
  categoryString
) => {
  const accounts = await web3.eth.getAccounts();
  const ownerAccount = accounts[0];

  const charityEventsContract = new web3.eth.Contract(
    charityEventsABI,
    charityEventsAddress
  );

  const category = EventCategory[categoryString];
  if (category === undefined) {
    console.error("Invalid category:", categoryString);
    return;
  }

  try {
    const tx = await charityEventsContract.methods
      .createEvent(eventName, eventDescription, targetAmount, endDate, category)
      .send({ from: ownerAccount });
    console.log(
      "Event created successfully. Transaction hash:",
      tx.transactionHash
    );
  } catch (error) {
    console.error("Error creating event:", error);
  }
};

const getEventDetail = async (eventId, charityEventsContract) => {
  const rawEventDetails = await charityEventsContract.methods
    .getEventDetails(eventId)
    .call();

  const eventDetails = {
    creator: rawEventDetails.creator,
    name: rawEventDetails.name,
    description: rawEventDetails.description,
    targetAmount: rawEventDetails.targetAmount,
    endDate: rawEventDetails.endDate,
    collectedAmount: rawEventDetails.collectedAmount,
    ratingSum: rawEventDetails.ratingSum,
    ratingCount: rawEventDetails.ratingCount,
    category: CategoryList[rawEventDetails.category],
    status: EventMilestoneStatus[rawEventDetails.status],
    committeeId: rawEventDetails.committeeId,
  };

  const rawMilestones = await charityEventsContract.methods
    .getMilestonesForEvent(eventId)
    .call();

  const milestones = await Promise.all(
    rawMilestones.map(async (milestone) => {
      return {
        creator: milestone.creator,
        name: milestone.name,
        description: milestone.description,
        spendedAmount: milestone.spendedAmount,
        targetAmount: milestone.targetAmount,
        endDate: milestone.endDate,
        ratingSum: milestone.ratingSum,
        ratingCount: milestone.ratingCount,
        committeeId: milestone.committeeId,
        completed: milestone.completed,
        status: EventMilestoneStatus[milestone.status],
      };
    })
  );

  return { eventDetails, milestones };
};

const listAllEvents = async () => {
  const charityEventsContract = new web3.eth.Contract(
    charityEventsABI,
    charityEventsAddress
  );

  const eventList = await charityEventsContract.methods.listAllEvents().call();
  const processedEvents = [];

  for (let eventId of eventList) {
    const { eventDetails, milestones } = await getEventDetail(
      eventId,
      charityEventsContract
    );

    processedEvents.push({
      ...eventDetails,
      milestones,
    });
  }

  console.log("Processed Events:", JSON.stringify(processedEvents, null, 2));
};

const getCommitteeDecision = async (committeeId) => {
  const accounts = await web3.eth.getAccounts();
  const ownerAccount = accounts[0];

  const randomizedCommitteeContract = new web3.eth.Contract(
    randomizedCommitteeABI,
    randomizedCommitteeAddress
  );

  const decisionDetails = await randomizedCommitteeContract.methods
    .getCommitteeDecision(committeeId)
    .call({ from: ownerAccount });

  const committeeDecision = {
    isCompleted: decisionDetails.isCompleted,
    validatorAddresses: decisionDetails.validatorAddresses,
    validatorVotes: decisionDetails.validatorVotes,
    validatorFeedbacks: decisionDetails.validatorFeedbacks,
    totalValidators: decisionDetails.totalValidators,
    finalDecision: decisionDetails.finalDecision,
    concatenatedFeedback: decisionDetails.concatenatedFeedback,
  };

  console.log("Committee Decision Details:", committeeDecision);
  return committeeDecision;
};

const addMilestone = async (
  eventId,
  milestoneName,
  description,
  targetAmount,
  endDate
) => {
  const accounts = await web3.eth.getAccounts();
  const ownerAccount = accounts[0];

  const charityEventsContract = new web3.eth.Contract(
    charityEventsABI,
    charityEventsAddress
  );

  try {
    const tx = await charityEventsContract.methods
      .addMilestone(eventId, milestoneName, description, targetAmount, endDate)
      .send({ from: ownerAccount });
    console.log(
      "Milestone added successfully. Transaction hash:",
      tx.transactionHash
    );
  } catch (error) {
    console.error("Error creating event:", error);
  }
};

// // Add Validators - It's admin priviledge
// (async () => {
//   for (const validatorAddress of validators) {
//     await addValidator(validatorAddress);
//   }
// })();

// // Create Event
// (async () => {
//   const eventName = "Clean Water Drive";
//   const eventDescription = "A charity event for providing clean water.";
//   const targetAmount = web3.utils.toWei("10", "ether");
//   const endDate = Math.floor(Date.now() / 1000 + 86400 * 7); // 7 days from now
//   const categoryString = "Environment";

//   await assignValidatorRole(charityEventsAddress);

//   await createEvent(
//     eventName,
//     eventDescription,
//     targetAmount,
//     endDate,
//     categoryString
//   );
// })();

// // Add Milestone
// (async () => {
//   const eventId = 1;
//   const milestoneName = "Distribute water";
//   const description =
//     "Need to distribute water to poor people, for that purpose we need 3 person";
//   const targetAmount = web3.utils.toWei("32", "ether");
//   const endDate = Math.floor(Date.now() / 1000 + 86400 * 7);

//   await addMilestone(
//     eventId,
//     milestoneName,
//     description,
//     targetAmount,
//     endDate
//   );
// })();

(async () => {
  await listAllEvents();
})();

// // Get CommitteeDecision
// (async () => {
//   await getCommitteeDecision(1);
// })();

// Get User UpComing Committees
// (async () => {
//   await getUserOngoingDecisions(validators[0]);
// })();
