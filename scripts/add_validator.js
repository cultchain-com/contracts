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
const validatorArtifacts = require("../artifacts/contracts/Validator.sol/Validator.json");
const fundraisingArtifacts = require("../artifacts/contracts/Fundraising.sol/Fundraising.json");
const { assignNewMochaID } = require("mocha/lib/utils");

const randomizedCommitteeABI = randomizedCommitteeArtifacts.abi;
const charityEventsABI = charityEventsArtifacts.abi;
const validatorABI = validatorArtifacts.abi;
const fundraisingABI = fundraisingArtifacts.abi;

const randomizedCommitteeAddress = "0x3d2c8Bc8A238b4a56977cee43144594311be4005";
const charityEventsAddress = "0x2B1bc45C1B0eCb92813B17E2F304c10F15719d0E";
const validatorAddress = "0x3d087a20898c9658CbA6C207022Dcc06b576881a";
const fundraisingAddress = "0xB1DCAA8d45470D17dC78BD30F3EecAB99C3d7ACf";

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

let validatorsPK = [
  "c894fb33b71ebe38a0cbd56aeebf7c6a801a0704d65859b85e6ea5a89a0d4fa2",
  "ac07f4474945693decef0d29529426ca742bc190575f114ff169c0157b8e2ebb",
  "f4b41c48318225af836ee52c036ea0b9dacf5a5e183883d118e9cb73be75bc52",
  "8eb2e13f92e850fb487aa6ff5aa786818d440395115ba91baf34e33d6722ac24",
  "bc0f5af46a233e092936e051fceaa8fd4a45aeeeb7eb516a4dd295622521248d",
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

const getValidatorRequestDetail = async (requestId, validatorContract) => {
  try {
    const validatorRequestDetails = await validatorContract.methods
      .ValidatorRequest(requestId)
      .call();
    return validatorRequestDetails;
  } catch (error) {
    console.error("Error geting validator request details:", error);
    throw error;
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

    const validatorContract = new web3.eth.Contract(
      validatorABI,
      validatorAddress
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
        } else if (
          CommitteeType[committeeDetail.committeeType] == "Validator"
        ) {
          const validatorDetail = await getValidatorRequestDetail(
            committeeDetail.committeeTypeId,
            validatorContract
          );
          committeeDetail.proposalDetail = validatorDetail;
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
  tokenUri,
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
  console.log("Category:", category);
  if (category === undefined) {
    console.error("Invalid category:", categoryString);
    return;
  }

  try {
    const tx = await charityEventsContract.methods
      .createEvent(
        tokenUri,
        eventName,
        eventDescription,
        targetAmount,
        endDate,
        category
      )
      .send({ from: ownerAccount, gasLimit: 1000000 });
    console.log("Event created successfully. Transaction hash:", tx);
  } catch (error) {
    console.error("Error creating event:", error);
  }
};

const donateToEvent = async (callerPk, eventID, message, amountInEther) => {
  const provider = new HDWalletProvider(
    callerPk,
    "https://rpc-mumbai.maticvigil.com/"
  );
  const web3 = new Web3(provider);
  const account = web3.eth.accounts.privateKeyToAccount(callerPk);

  const donationAmount = web3.utils.toWei(amountInEther, "ether");

  const fundraisingContract = new web3.eth.Contract(
    fundraisingABI,
    fundraisingAddress
  );

  try {
    await fundraisingContract.methods
      .donateToEvent(eventID, message)
      .send({ from: account.address, value: donationAmount });
    console.log("Donate to the eventID:", eventID);
  } catch (error) {
    console.log("Failed to donate:", error);
  }
};

const requestWithdraw = async (eventId) => {
  const accounts = await web3.eth.getAccounts();
  const ownerAccount = accounts[0];
  const charityEventsContract = new web3.eth.Contract(
    charityEventsABI,
    charityEventsAddress
  );
  const amount = await charityEventsContract.methods
    .possibleMilestoneAmount(eventId)
    .call();
  const fundraisingContract = new web3.eth.Contract(
    fundraisingABI,
    fundraisingAddress
  );
  try {
    await fundraisingContract.methods
      .requestWithdraw(eventId, amount)
      .send({ from: ownerAccount });
  } catch (error) {
    console.log("WIthdraw rejected:", error);
  }
};

const getEventDonationList = async (eventId) => {
  const fundraisingContract = new web3.eth.Contract(
    fundraisingABI,
    fundraisingAddress
  );

  const eventDonationList = await fundraisingContract.methods
    .getEventDonations(eventId)
    .call();
  console.log("Event Donations:", eventDonationList);
};

const getDonorsLeaderboard = async (numOfTopDonors) => {
  const fundraisingContract = new web3.eth.Contract(
    fundraisingABI,
    fundraisingAddress
  );

  const leaderBoard = await fundraisingContract.methods
    .getTopDonors(numOfTopDonors)
    .call();
  console.log("Top Donors:", leaderBoard);
};

const applyForValidator = async (ipfsHash) => {
  const provider = new HDWalletProvider(
    "4d4bc6e267e83b48f9dd2b488ea530c67a1bd0e9e517fb50026befa7e3d25ef7",
    "https://rpc-mumbai.maticvigil.com/"
  );
  const web3 = new Web3(provider);
  const accounts = await web3.eth.getAccounts();
  const ownerAccount = accounts[0];
  const validatorContract = new web3.eth.Contract(
    validatorABI,
    validatorAddress
  );
  try {
    await validatorContract.methods
      .applyForValidator(ipfsHash)
      .send({ from: ownerAccount });
    console.log("Validator request submitted successfully.");
  } catch (error) {
    console.log("Couldn't register the request:", error);
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
  console.log("Geting Event lists");
  const eventList = await charityEventsContract.methods.listAllEvents().call();
  console.log("All Events:", eventList);
  const processedEvents = [];

  for (let eventId of eventList) {
    const { eventDetails, milestones } = await getEventDetail(
      eventId,
      charityEventsContract
    );
    console.log("Event details:", eventDetails);

    processedEvents.push({
      eventId,
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

const recordDecision = async (
  callerPk, // caller pk accepted to enable us to initiate the web3 object and sign the tx, you must take another approach (only accept the address.)
  committeeId,
  decision,
  feedback
) => {
  const provider = new HDWalletProvider(
    callerPk,
    "https://rpc-mumbai.maticvigil.com/"
  );
  const web3 = new Web3(provider);
  // const accounts = await web3.eth.getAccounts();
  // const callerAccount = accounts[0];

  const randomizedCommitteeContract = new web3.eth.Contract(
    randomizedCommitteeABI,
    randomizedCommitteeAddress
  );

  const account = web3.eth.accounts.privateKeyToAccount(callerPk);

  console.log("Retrieving isMember");

  const isCommitteeMember = await randomizedCommitteeContract.methods
    .isCommitteeMember(committeeId, account.address)
    .call();

  console.log("Is committee member?", isCommitteeMember);

  if (isCommitteeMember) {
    try {
      const result = await randomizedCommitteeContract.methods
        .recordDecision(committeeId, decision, feedback)
        .send({ from: account.address });
      console.log("Decision Recorded:", result);
    } catch (error) {
      console.error("Error recording decision:", error);
    }
  } else {
    console.log("The address is not a committee member");
  }
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
//   const eventName = "Educate poor children";
//   const eventDescription = "provide good education services for children";
//   const targetAmount = web3.utils.toWei("0.2", "ether");
//   const endDate = Math.floor(Date.now() / 1000 + 86400 * 10); // 7 days from now
//   const categoryString = "Education";
//   const tokenUri = "http://www.cultchain.com/2";

//   await createEvent(
//     tokenUri,
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
//   const milestoneName = "Buy bottles for distributing water 1";
//   const description = "we need lot's of money for doing the distribution II";
//   const targetAmount = web3.utils.toWei("0.01", "ether");
//   const endDate = Math.floor(Date.now() / 1000 + 86400 * 7);

//   await addMilestone(
//     eventId,
//     milestoneName,
//     description,
//     targetAmount,
//     endDate
//   );
// })();

// (async () => {
//   await listAllEvents();
// })();

// Get CommitteeDecision
// (async () => {
//   await getCommitteeDecision(1);
// })();

// // Get User UpComing Committees
// (async () => {
//   await getUserOngoingDecisions(validators[0]);
// })();

// // Record User Decision
// (async () => {
//   await recordDecision(
//     validatorsPK[2], // this is the private key, in the frontend section you must take it from metamask
//     1,
//     false,
//     "I don't like it actually"
//   );
// })();

// // Get Committee Decision
// (async () => {
//   await getCommitteeDecision(1);
// })();

// Donate to Event
(async () => {
  await donateToEvent(validatorsPK[4], 1, "To Educate poor child", "0.01");
})();

// // Donor Leaderboard
// (async () => {
//   await getDonorsLeaderboard(2);
// })();

// Creator Leaderboard
