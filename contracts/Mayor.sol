// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Mayor {
    struct Conditions {
        uint32 quorum;
        uint32 envelopes_casted;
        uint32 envelopes_opened;
        bool open;
        bool valid;
    }

    struct Candidate {
        string firstName;
        string lastName;
        string imageUrl;
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
        require(voting_condition.envelopes_casted < voting_condition.quorum, "Cannot vote now, voting quorum has been reached");
        _;
    }

    modifier canOpen() {
        require(voting_condition.envelopes_casted == voting_condition.quorum, "Cannot open an envelope, voting quorum not reached yet");
        _;
    }

    modifier canCheckOutcome() {
        require(voting_condition.envelopes_opened == voting_condition.quorum, "Cannot check the winner, need to open all the sent envelopes");
        require(voting_condition.open != false, "The elections have already been declared");
        _;
    }

    modifier canGetResults() {
        require(voting_condition.open == false, "The elections have not been declared yet");
        require(voting_condition.valid == true, "The elections are invalid.!");
        _;
    }

    address payable public escrow;
    Group[] public groups;

    mapping(address => bytes32) envelopes;
    Conditions voting_condition;
    mapping(address => Candidate) candidates;
    mapping(address => bool) public envelopeOpened;
    address[] voters;

    constructor(
        address payable _escrow,
        uint32 _quorum,
        string[] memory _groupNames,
        string[] memory _groupPictures,
        address[] memory _groupAddresses
    ) {
        require(_groupNames.length == _groupPictures.length && _groupNames.length == _groupAddresses.length, "Mismatched input arrays");

        escrow = _escrow;
        voting_condition = Conditions({quorum: _quorum, envelopes_casted: 0, envelopes_opened: 0, open: true, valid: true});

        for (uint j = 0; j < _groupNames.length; j++) {
            address[] memory initialCandidateAddresses = new address[](1);
            initialCandidateAddresses[0] = _groupAddresses[j];

            groups.push(Group({
                name: _groupNames[j],
                pictureUrl: _groupPictures[j],
                votes: 0,
                candidateAddresses: initialCandidateAddresses
            }));
        }
    }

    function addCandidateToGroup(address groupAddress, address candidateAddress, string memory firstName, string memory lastName, string memory imageUrl) public {
        require(isGroupAddress(groupAddress), "Group does not exist");
        candidates[candidateAddress] = Candidate({
            firstName: firstName,
            lastName: lastName,
            imageUrl: imageUrl
        });
        for (uint i = 0; i < groups.length; i++) {
            if (groups[i].candidateAddresses[0] == groupAddress) {
                groups[i].candidateAddresses.push(candidateAddress);
                break;
            }
        }
    }

    function cast_envelope(bytes32 _envelope) public canVote {
        if (envelopes[msg.sender] == 0x0) {
            voting_condition.envelopes_casted++;
        }
        envelopes[msg.sender] = _envelope;
        emit EnvelopeCast(msg.sender);
    }

    function open_envelope(uint _sigil, address _group) public canOpen {
        require(envelopes[msg.sender] != 0x0, "The sender has not cast any votes");
        require(!envelopeOpened[msg.sender], "Envelope has already been opened");
        bytes32 _casted_envelope = envelopes[msg.sender];
        bytes32 _sent_envelope = compute_envelope(_sigil, _group);

        require(_casted_envelope == _sent_envelope, "Sent envelope does not correspond to the one cast");

        envelopeOpened[msg.sender] = true;
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

    function mayor_or_sayonara() canCheckOutcome public {
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
            voting_condition.valid = false;
            emit InvalidElections(escrow);
        } else {
            emit NewMayor(electedGroup);
        }
    }

    function get_status(address addr) public view returns (uint32, uint32, bool, bool, bool) {
        return (
            voting_condition.quorum,
            voting_condition.envelopes_casted,
            (envelopes[addr] != 0x0),
            voting_condition.open,
            is_candidate(addr)
        );
    }

    function getAllDetails() public view returns (
        string[] memory groupNames,
        string[] memory groupPictures,
        address[][] memory groupCandidatesArray,
        address[] memory candidateAddresses,
        string[] memory candidateFirstNames,
        string[] memory candidateLastNames,
        string[] memory candidateImageUrls
    ) {
        uint groupCount = groups.length;
        uint candidateCount = 0;

        for (uint i = 0; i < groupCount; i++) {
            candidateCount += groups[i].candidateAddresses.length;
        }

        groupNames = new string[](groupCount);
        groupPictures = new string[](groupCount);
        groupCandidatesArray = new address[][](groupCount);
        candidateAddresses = new address[](candidateCount);
        candidateFirstNames = new string[](candidateCount);
        candidateLastNames = new string[](candidateCount);
        candidateImageUrls = new string[](candidateCount);

        uint k = 0;
        for (uint i = 0; i < groupCount; i++) {
            Group storage group = groups[i];
            groupNames[i] = group.name;
            groupPictures[i] = group.pictureUrl;
            groupCandidatesArray[i] = new address[](group.candidateAddresses.length);

            for (uint j = 0; j < group.candidateAddresses.length; j++) {
                address candidateAddr = group.candidateAddresses[j];
                groupCandidatesArray[i][j] = candidateAddr;
                candidateAddresses[k] = candidateAddr;
                candidateFirstNames[k] = candidates[candidateAddr].firstName;
                candidateLastNames[k] = candidates[candidateAddr].lastName;
                candidateImageUrls[k] = candidates[candidateAddr].imageUrl;
                k++;
            }
        }

        return (
            groupNames,
            groupPictures,
            groupCandidatesArray,
            candidateAddresses,
            candidateFirstNames,
            candidateLastNames,
            candidateImageUrls
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
}
