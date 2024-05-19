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
        uint32 votes;
        string firstName;
        string lastName;
        string imageUrl; // Add imageUrl to the struct
    }

    event NewMayor(address indexed _candidate);
    event InvalidElections(address indexed _escrow);
    event EnvelopeCast(address indexed _voter);
    event EnvelopeOpen(address indexed _voter, address indexed _sign);

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
        require(voting_condition.open != false, "The elections has already been decleared");
        _;
    }
    modifier canGetResults() {
        require(voting_condition.open == false, "The elections has not been declared yet");
        require(voting_condition.valid == true, "The elections are invalid.!");
        _;
    }



    // Initialization variables
    address[] public candidate;
    address payable public escrow;

    // Voting phase variables
    mapping(address => bytes32) envelopes;

    Conditions voting_condition;

    // Refund phase variables
    mapping(address => Candidate) candidates;


    mapping(address => bool) public envelopeOpened;


    address[] voters;

    constructor(address[] memory _candidates,
        address payable _escrow,
        uint32 _quorum,
        string[] memory _firstNames,
        string[] memory _lastNames,
        string[] memory _imageUrls // Add imageUrls as a parameter
    ) {
        require(_candidates.length == _firstNames.length && _candidates.length == _lastNames.length && _candidates.length == _imageUrls.length, "Mismatched input arrays");

        for (uint i = 0; i < _candidates.length; i++) {
            address key = _candidates[i];
            candidate.push(key);
            candidates[key] = Candidate({
                votes: 0,
                firstName: _firstNames[i],
                lastName: _lastNames[i],
                imageUrl: _imageUrls[i]
            });
        }

        escrow = _escrow;
        voting_condition = Conditions({quorum: _quorum, envelopes_casted: 0, envelopes_opened: 0, open: true, valid: true});

    }

    function cast_envelope(bytes32 _envelope) public canVote {
        if (envelopes[msg.sender] == 0x0) {
            voting_condition.envelopes_casted++;
        }
        envelopes[msg.sender] = _envelope;
        emit EnvelopeCast(msg.sender);
    }

    function open_envelope(uint _sigil, address _sign) public canOpen {

        require(envelopes[msg.sender] != 0x0, "The sender has not casted any votes");
        require(!envelopeOpened[msg.sender], "Envelope has already been opened");
        bytes32 _casted_envelope = envelopes[msg.sender];
        bytes32 _sent_envelope = compute_envelope(_sigil, _sign);

        require(_casted_envelope == _sent_envelope, "Sent envelope does not correspond to the one cast");

        envelopeOpened[msg.sender] = true;
        //hasConfirmed[msg.sender] = true;
        candidates[_sign].votes += 1;
        voting_condition.envelopes_opened++;
        voters.push(msg.sender);

        emit EnvelopeOpen(msg.sender, _sign);
    }

    function mayor_or_sayonara() canCheckOutcome public {

        //closing voting
        voting_condition.open = false;

        //checking winner and manage payments
        address elected = address(0);
        uint maxVotes = 0;
        bool invalid = false;
        for (uint i=0; i<candidate.length; i++){
            Candidate memory cnd = candidates[candidate[i]];

            if (cnd.votes > maxVotes){
                elected = candidate[i];
                maxVotes = cnd.votes;
                invalid = false;
            } else if (cnd.votes == maxVotes){
                invalid = true;
            }
        }

        if (invalid) {
            voting_condition.valid = false;
            emit InvalidElections(escrow);
        } else {
            emit NewMayor(elected);
        }
    }

    function get_status(address addr) public view returns(uint32, uint32, bool, bool, bool){
        return (voting_condition.quorum, voting_condition.envelopes_casted, (envelopes[addr] != 0x0), voting_condition.open, is_candidate(addr));
    }

    function getCandidateNames() public view returns (address[] memory addresses, string[] memory firstNames, string[] memory lastNames, string[] memory imageUrls) {
        addresses = new address[](candidate.length);
        firstNames = new string[](candidate.length);
        lastNames = new string[](candidate.length);
        imageUrls = new string[](candidate.length);

        for (uint i = 0; i < candidate.length; i++) {
            addresses[i] = candidate[i];
            firstNames[i] = candidates[candidate[i]].firstName;
            lastNames[i] = candidates[candidate[i]].lastName;
            imageUrls[i] = candidates[candidate[i]].imageUrl;
        }

        return (addresses, firstNames, lastNames, imageUrls);
    }

    function get_results() public view canGetResults returns (address[] memory, uint[] memory, string[] memory firstNames, string[] memory lastNames, string[] memory imageUrls) {
        uint[] memory all_votes = new uint[](candidate.length);
        firstNames = new string[](candidate.length);
        lastNames = new string[](candidate.length);
        imageUrls = new string[](candidate.length);

        for (uint i = 0; i < candidate.length; i++) {
            all_votes[i] = candidates[candidate[i]].votes;
            firstNames[i] = candidates[candidate[i]].firstName;
            lastNames[i] = candidates[candidate[i]].lastName;
            imageUrls[i] = candidates[candidate[i]].imageUrl;
        }

        return (candidate, all_votes, firstNames, lastNames, imageUrls);
    }

    function compute_envelope(uint _sigil, address _sign) private pure returns (bytes32) {
        return keccak256(abi.encode(_sigil, _sign));
    }

    function is_candidate(address addr) private view returns (bool) {
        for (uint i = 0; i < candidate.length; i++) {
            if (addr == candidate[i]) {
                return true;
            }
        }
        return false;
    }

//    function get_deadline() public view returns (uint256) {
//        return voting_condition.deadline;
//    }
}
