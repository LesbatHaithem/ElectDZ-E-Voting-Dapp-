// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

contract Mayor {

    // Structs, events, and modifiers

    // Store refund data

    // Data to manage the confirmation
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
    }

    event NewMayor(address _candidate);
    event Sayonara(address _escrow);
    event EnvelopeCast(address _voter);
    event InvalidElections(address _escrow);

    // event EnvelopeOpen(address _voter, uint _soul, address _sign);
    event EnvelopeOpen(address _voter, address _sign);


    // Someone can vote as long as the quorum is not reached
    modifier canVote() {
        require(voting_condition.envelopes_casted < voting_condition.quorum, "Cannot vote now, voting quorum has been reached");
        _;
    }

    // Envelopes can be opened only after receiving the quorum
    modifier canOpen() {
        require(voting_condition.envelopes_casted == voting_condition.quorum, "Cannot open an envelope, voting quorum not reached yet");
        _;
    }

    // The outcome of the confirmation can be computed as soon as all the casted envelopes have been opened
    modifier canCheckOutcome() {
        require(voting_condition.envelopes_opened == voting_condition.quorum, "Cannot check the winner, need to open all the sent envelopes");
        require(voting_condition.open != false, "The elections has already been decleared");
        _;
    }

    //only if is finished
    modifier canGetResults() {
        require(voting_condition.open == false, "The elections has not been declared yet");
        require(voting_condition.valid == true, "The elections are invalid.!");
        _;
    }


    modifier canDeposit() {
        require(voting_condition.open == true, "The elections are over");
        require(is_candidate(msg.sender) == true, "You are not a candidate");
        _;
    }

    // State attributes

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

    /// @notice The constructor only initializes internal variables
    /// @param _candidates (address) The address of the mayor candidate
    /// @param _escrow (address) The address of the escrow account
    /// @param _quorum (address) The number of voters required to finalize the confirmation
    constructor(address[] memory _candidates, address payable _escrow, uint32 _quorum, string[] memory _firstNames, string[] memory _lastNames) {
        require(_candidates.length == _firstNames.length && _candidates.length == _lastNames.length, "Mismatched input arrays");

        for (uint i=0; i<_candidates.length; i++){
            address key = _candidates[i];
            candidate.push(key);
            candidates[key] = Candidate({ votes: 0, firstName: _firstNames[i], lastName: _lastNames[i] });
        }

        escrow = _escrow;
        voting_condition = Conditions({quorum: _quorum, envelopes_casted: 0, envelopes_opened: 0, open: true, valid: true});
    }

    /// @notice Store a received voting envelope
    /// @param _envelope keccak256 hash of envelope
    function cast_envelope(bytes32 _envelope) canVote public {

        if(envelopes[msg.sender] == 0x0)
            voting_condition.envelopes_casted++;

        envelopes[msg.sender] = _envelope;
        emit EnvelopeCast(msg.sender);

    }


    /// @notice Deposit some funds


    /// @notice Open an envelope and store the vote information
    /// @param _sigil (uint) The secret sigil of a voter
    /// @param _sign (address) The voting preference
    /// @dev The soul is sent as crypto
    /// @dev Need to recompute the hash to validate the envelope previously casted
    function open_envelope(uint _sigil, address _sign) canOpen public {
        require(envelopes[msg.sender] != 0x0, "The sender has not casted any votes");
        require(!envelopeOpened[msg.sender], "Envelope has already been opened");

        bytes32 _casted_envelope = envelopes[msg.sender];
        bytes32 _sent_envelope = compute_envelope(_sigil, _sign);

        require(_casted_envelope == _sent_envelope, "Sent envelope does not correspond to the one casted");

        // Mark the envelope as opened to prevent re-opening
        envelopeOpened[msg.sender] = true;

        // Increment the vote count for the candidate
        candidates[_sign].votes += 1;

        // Update the number of opened envelopes
        voting_condition.envelopes_opened++;
        voters.push(msg.sender);

        // Emit the event to log the action
        emit EnvelopeOpen(msg.sender, _sign);
    }

    /// @notice Either confirm or kick out the candidate. Refund the electors who voted for the losing outcome
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

    //This API is used by the FlowScreen to display the proper step
    //NOTE: i don't consider a security problem the possibility that someone cheat on his address
    // because the information that would leak it is not so private
    //@param address
    //It returns a list of:
    //uint32 => quorum
    //uint32 => votes casted
    //bool => if passed addr has still to open his letter
    //bool => election open
    //bool => the addr is a candidate
    function get_status(address addr) public view returns(uint32, uint32, bool, bool, bool){
        return (voting_condition.quorum, voting_condition.envelopes_casted, (envelopes[addr] != 0x0), voting_condition.open, is_candidate(addr));
    }
//    function get_candidates() public view returns(address[] memory, address[] memory, uint[] memory){
//        address[] memory _candidates = new address[](candidate.length);
//        address[] memory _candidates2 = new address[](candidate.length);
//        uint[] memory deposited = new uint[](candidate.length);
//        for (uint i=0; i<candidate.length; i++){
//            if (candidates[candidate[i]].deposit > 0){
//                _candidates[i] = candidate[i];
//                deposited[i] = candidates[candidate[i]].deposit;
//            } else {
//                _candidates2[i] = candidate[i];
//            }
//        }
//        return (_candidates, _candidates2, deposited);
//    }
    function getCandidateNames() public view returns(address[] memory addresses, string[] memory firstNames, string[] memory lastNames) {
        addresses = new address[](candidate.length);
        firstNames = new string[](candidate.length);
        lastNames = new string[](candidate.length);

        for (uint i = 0; i < candidate.length; i++) {
            addresses[i] = candidate[i];
            firstNames[i] = candidates[candidate[i]].firstName;
            lastNames[i] = candidates[candidate[i]].lastName;
        }

        return (addresses, firstNames, lastNames);
    }

//    function get_results() canGetResults public view returns(address[] memory, uint[] memory, uint[] memory){
//        uint[] memory all_souls = new uint[](candidate.length);
//        uint[] memory all_votes = new uint[](candidate.length);
//        for (uint i=0; i<candidate.length; i++){
//            all_souls[i] = candidates[candidate[i]].souls;
//            if (candidates[candidate[i]].souls == 0)
//                all_souls[i] = candidates[candidate[i]].history_souls;
//            all_votes[i] = candidates[candidate[i]].votes;
//        }
//        return (candidate, all_souls, all_votes);
//    }
    function get_results() canGetResults public view returns(address[] memory, uint[] memory, string[] memory firstNames, string[] memory lastNames){
        uint[] memory all_votes = new uint[](candidate.length);
        firstNames = new string[](candidate.length);
        lastNames = new string[](candidate.length);

        for (uint i=0; i<candidate.length; i++){
            all_votes[i] = candidates[candidate[i]].votes;
            firstNames[i] = candidates[candidate[i]].firstName;
            lastNames[i] = candidates[candidate[i]].lastName;
        }
        return (candidate, all_votes , firstNames, lastNames);
    }

    /// @notice Compute a voting envelope
    /// @param _sigil (uint) The secret sigil of a voter
    /// @param _sign (address) The voting preference
    function compute_envelope(uint _sigil, address _sign) private pure returns(bytes32) {
        return keccak256(abi.encode(_sigil, _sign));
    }


    //@notice check if an addr is a candidate
    function is_candidate(address addr) private view returns(bool){
        for (uint i=0; i<candidate.length; i++){
            if (addr == candidate[i])
                return true;
        }
        return false;
    }}


