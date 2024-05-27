// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract Deputies {

    struct Conditions {
        uint256 deadline;
        uint32 envelopes_casted;
        uint32 envelopes_opened;
        bool open;
        bool valid_results;
    }

    struct Candidate {
        string firstName;
        string lastName;
        string imageUrl;
        string gender;
        string jobPosition;
        string electoralDistrict;
        string politicalAffiliation;
        uint32 age;
    }

    struct Group {
        string name;
        string pictureUrl;
        uint32 votes;
        address[] candidateAddresses;
    }

    event NewMayor(address indexed _group);
    event InvalidElections(address indexed _escrow);
    event EnvelopeCast(address indexed _voter);
    event EnvelopeOpen(address indexed _voter, address indexed _group);

    modifier canVote() {
        require(block.timestamp <= voting_condition.deadline, "Voting period has ended");
        require(!hasConfirmed[msg.sender], "You have already confirmed your vote");
        require(envelopes[msg.sender] == 0x0, "You have already cast your vote");
        _;
    }

    modifier canConfirm() {
        require(block.timestamp <= voting_condition.deadline, "Voting period has ended");
        require(envelopes[msg.sender] != 0x0, "You have not cast any votes");
        require(!envelopeOpened[msg.sender], "Envelope has already been confirmed");
        require(!hasConfirmed[msg.sender], "You have already confirmed your vote");
        _;
    }

    modifier canCheckOutcome() {
        require(block.timestamp > voting_condition.deadline, "Cannot check the winner before the deadline");
        require(voting_condition.open != false, "The elections have already been declared");
        _;
    }

    modifier canGetResults() {
        require(!voting_condition.open, "The elections have not been declared yet");
        require(voting_condition.valid_results == true, "The elections are invalid");
        _;
    }

    Group[] public groups;
    address payable public escrow;

    mapping(address => bytes32) envelopes;
    Conditions voting_condition;
    mapping(address => Candidate) candidates;
    mapping(address => bool) public envelopeOpened;
    mapping(address => bool) public hasConfirmed;
    address[] voters;

    constructor(
        address payable _escrow,
        uint256 _duration,
        string[] memory _groupNames,
        string[] memory _groupPictures,
        address[] memory _groupAddresses
    ) {
        require(_groupNames.length == _groupPictures.length && _groupNames.length == _groupAddresses.length, "Mismatched input arrays");

        for (uint j = 0; j < _groupNames.length; j++) {
            address[] memory initialCandidateAddresses = new address[](1);
            initialCandidateAddresses[0] = _groupAddresses[j];

            groups.push(Group({
                votes: 0,
                name: _groupNames[j],
                pictureUrl: _groupPictures[j],
                candidateAddresses: initialCandidateAddresses
            }));
        }

        escrow = _escrow;
        voting_condition = Conditions({
            envelopes_casted: 0,
            envelopes_opened: 0,
            open: true,
            valid_results: true,
            deadline: block.timestamp + _duration
        });
    }

    function cast_envelope(bytes32 _envelope) public canVote {
        if (envelopes[msg.sender] == 0x0) {
            voting_condition.envelopes_casted++;
        }
        envelopes[msg.sender] = _envelope;
        emit EnvelopeCast(msg.sender);
    }

    function confirm_envelope(uint _sigil, address _group) public canConfirm {
        bytes32 _casted_envelope = envelopes[msg.sender];
        bytes32 _sent_envelope = compute_envelope(_sigil, _group);

        require(_casted_envelope == _sent_envelope, "Sent envelope does not correspond to the one cast");

        envelopeOpened[msg.sender] = true;
        hasConfirmed[msg.sender] = true;
        for (uint i = 0; i < groups.length; i++) {
            if (groups[i].candidateAddresses[0] == _group) {
                groups[i].votes += 1;
                break;
            }
        }
        voting_condition.envelopes_opened++;
        voters.push(msg.sender);

        emit EnvelopeOpen(msg.sender, _group);
    }

    function valid_candidate_check() canCheckOutcome public {
        voting_condition.open = false;

        uint maxVotes = 0;
        bool invalid = false;
        address electedGroup = address(0);

        for (uint i = 0; i < groups.length; i++) {
            if (groups[i].votes > maxVotes) {
                electedGroup = groups[i].candidateAddresses[0];
                maxVotes = groups[i].votes;
                invalid = false;
            } else if (groups[i].votes == maxVotes) {
                invalid = true;
            }
        }

        if (invalid) {
            voting_condition.valid_results = false;
            emit InvalidElections(escrow);
        } else {
            emit NewMayor(electedGroup);
        }
    }

    function auto_declare_results() public canCheckOutcome {
        if (voting_condition.open) {
            valid_candidate_check();
        }
    }

    function get_status(address addr) public view returns (uint32, uint32, bool, bool, bool) {
        return (
            voting_condition.envelopes_opened,
            voting_condition.envelopes_casted,
            (envelopes[addr] != 0x0),
            voting_condition.open,
            is_candidate(addr)
        );
    }

    function addCandidateToGroup(
        address groupAddress,
        address candidateAddress,
        string memory firstName,
        string memory lastName,
        string memory imageUrl,
        string memory gender,
        string memory jobPosition,
        string memory electoralDistrict,
        string memory politicalAffiliation,
        uint32 age
    ) public {
        require(isGroupAddress(groupAddress), "Group does not exist");
        candidates[candidateAddress] = Candidate({
            firstName: firstName,
            lastName: lastName,
            imageUrl: imageUrl,
            gender: gender,
            jobPosition: jobPosition,
            electoralDistrict: electoralDistrict,
            politicalAffiliation: politicalAffiliation,
            age: age
        });
        for (uint i = 0; i < groups.length; i++) {
            if (groups[i].candidateAddresses[0] == groupAddress) {
                groups[i].candidateAddresses.push(candidateAddress);
                break;
            }
        }
    }

    function getGroupDetails() public view returns (
        string[] memory groupNames,
        string[] memory groupPictures,
        address[][] memory groupCandidatesArray
    ) {
        uint groupCount = groups.length;

        groupNames = new string[](groupCount);
        groupPictures = new string[](groupCount);
        groupCandidatesArray = new address[][](groupCount);

        for (uint i = 0; i < groupCount; i++) {
            Group storage group = groups[i];
            groupNames[i] = group.name;
            groupPictures[i] = group.pictureUrl;
            groupCandidatesArray[i] = group.candidateAddresses;
        }

        return (groupNames, groupPictures, groupCandidatesArray);
    }

    function getCandidateDetails() public view returns (
        address[] memory candidateAddresses,
        string[] memory candidateFirstNames,
        string[] memory candidateLastNames,
        string[] memory candidateImageUrls,
        string[] memory candidateGenders,
        string[] memory candidateJobPositions,
        string[] memory candidateElectoralDistricts,
        string[] memory candidatePoliticalAffiliations,
        uint32[] memory candidateAges
    ) {
        uint candidateCount = 0;

        for (uint i = 0; i < groups.length; i++) {
            candidateCount += groups[i].candidateAddresses.length;
        }

        candidateAddresses = new address[](candidateCount);
        candidateFirstNames = new string[](candidateCount);
        candidateLastNames = new string[](candidateCount);
        candidateImageUrls = new string[](candidateCount);
        candidateGenders = new string[](candidateCount);
        candidateJobPositions = new string[](candidateCount);
        candidateElectoralDistricts = new string[](candidateCount);
        candidatePoliticalAffiliations = new string[](candidateCount);
        candidateAges = new uint32[](candidateCount);

        uint k = 0;
        for (uint i = 0; i < groups.length; i++) {
            for (uint j = 0; j < groups[i].candidateAddresses.length; j++) {
                address candidateAddr = groups[i].candidateAddresses[j];
                candidateAddresses[k] = candidateAddr;
                candidateFirstNames[k] = candidates[candidateAddr].firstName;
                candidateLastNames[k] = candidates[candidateAddr].lastName;
                candidateImageUrls[k] = candidates[candidateAddr].imageUrl;
                candidateGenders[k] = candidates[candidateAddr].gender;
                candidateJobPositions[k] = candidates[candidateAddr].jobPosition;
                candidateElectoralDistricts[k] = candidates[candidateAddr].electoralDistrict;
                candidatePoliticalAffiliations[k] = candidates[candidateAddr].politicalAffiliation;
                candidateAges[k] = candidates[candidateAddr].age;
                k++;
            }
        }

        return (
            candidateAddresses,
            candidateFirstNames,
            candidateLastNames,
            candidateImageUrls,
            candidateGenders,
            candidateJobPositions,
            candidateElectoralDistricts,
            candidatePoliticalAffiliations,
            candidateAges
        );
    }

    function get_results() public view canGetResults returns (
        address[] memory groupAddresses,
        uint32[] memory groupVotes,
        string[] memory groupNames,
        string[] memory groupPictures
    ) {
        uint groupCount = groups.length;
        groupAddresses = new address[](groupCount);
        groupVotes = new uint32[](groupCount);
        groupNames = new string[](groupCount);
        groupPictures = new string[](groupCount);

        for (uint i = 0; i < groupCount; i++) {
            Group storage group = groups[i];
            groupAddresses[i] = group.candidateAddresses[0];
            groupVotes[i] = group.votes;
            groupNames[i] = group.name;
            groupPictures[i] = group.pictureUrl;
        }

        return (
            groupAddresses,
            groupVotes,
            groupNames,
            groupPictures
        );
    }

    function compute_envelope(uint _sigil, address groupAddr) private pure returns (bytes32) {
        return keccak256(abi.encode(_sigil, groupAddr));
    }

    function is_candidate(address addr) private view returns (bool) {
        return bytes(candidates[addr].firstName).length > 0;
    }

    function isGroupAddress(address groupAddr) private view returns (bool) {
        for (uint i = 0; i < groups.length; i++) {
            if (groups[i].candidateAddresses[0] == groupAddr) {
                return true;
            }
        }
        return false;
    }

    function get_deadline() public view returns (uint256) {
        return voting_condition.deadline;
    }

    function get_vote_count() public view returns (uint256) {
        return voters.length;
    }
}
