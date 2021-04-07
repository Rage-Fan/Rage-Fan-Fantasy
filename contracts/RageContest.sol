pragma solidity 0.5.16;

import "./EIP712MetaTransaction.sol";
import "./RageToken.sol";

contract RageContest is EIP712MetaTransaction {
 
    RageToken private token;

    string public contestId;
    string public name;
    string public contestTitle;
    uint256 public contestFees;
    uint256 public winningAmount;
 
    bool public isActive;
    address public owner;
    
    Player[] public players;

    uint public prizePool;
    uint public decimals;
    
    uint public maxContestants;
    uint public minContestants;
    uint public startTime;
    uint public endTime;
    bool public canceled;  
    bool public settled; 
    address  public player; 
    address[] public contestants; 
    
    struct Player {
      string id; 
      string name;
      uint points;
      string captain;  //C,VC,P  
    }

    mapping (uint => Player) public playersData;
    mapping (uint => bool) internal playersList;

    mapping (address => uint256) public fundsByParticipants;
    mapping  (address => mapping (address => uint256) ) public fundsByParticipantsByTeam;
    mapping (address => uint256) public fundsByWinners;
    mapping (address => bool) public participantsList;

    event ContestCanceled();
    event LogPlay(address player);
    event ApprovePlay(address player);
     
    event PlayerDataUpdated();
    event LogWithdrawal(address withdrawer,  uint amount);

    event ContestCreatedEvent(address sender, string  _id, string  _name,  uint _startTime, uint _endTime, 
                string  _contestTitle);
    /*
    * Contract Constructor
    */
    constructor(address _adminOwner, string memory _id, string memory _name,  uint _startTime, uint _endTime, 
                string memory _contestTitle,
                uint256 _contestFees, 
                uint256 _winningAmount, 
                bool _isActive,
                address _token ) 
    public 
    EIP712MetaTransaction("RageContestContract","1", 80001)
    {  
        //Used constructor
        require(bytes(name).length == 0); // ensure not init'd already.
        require(bytes(_name).length > 0);

                contestId       =   _id;
                name            =   _name;
                startTime       =   _startTime;
                endTime         =   _endTime;
                contestTitle    =   _contestTitle;
                contestFees     =   _contestFees;
                winningAmount   =   _winningAmount;
                isActive        =   _isActive;
                owner = _adminOwner;            
                token = RageToken(_token); 
                canceled = false;
                settled = false;                      
    }

/*
** not in use
 function init(string memory _id, string memory _name,  uint _startTime, uint _endTime, 
                string memory _contestTitle,
                uint256 _contestFees, 
                uint256 _winningAmount, 
                bool _isActive,
                address _token
                ) public {
                    
        require(bytes(name).length == 0); // ensure not init'd already.
        require(bytes(_name).length > 0);

                contestId       =   _id;
                name            =   _name;
                startTime       =   _startTime;
                endTime         =   _endTime;
                contestTitle    =   _contestTitle;
                contestFees     =   _contestFees;
                winningAmount   =   _winningAmount;
                isActive        =   _isActive;
                owner = msgSender();            
                token = RageToken(_token); 
                canceled = false;
                settled = false;  
                
         }
*/

 function callContest() public {
    emit ContestCreatedEvent(address(this), contestId, name, startTime, endTime, contestTitle);
  }   

function withdraw(uint256 _amount)
        public         
        returns (bool)
        {
            require(_amount <= fundsByParticipants[msgSender()]);
                fundsByParticipants[msgSender()] = fundsByParticipants[msgSender()] - _amount;
            
            require(token.transfer(msgSender(), _amount));

            emit LogWithdrawal(msgSender(), _amount);
            return true;
        }

function withdrawWinningAmount(uint256 _amount)
        public         
        returns (bool)
        {
            require(_amount <= fundsByParticipants[msgSender()]);
            fundsByParticipants[msgSender()] = fundsByParticipants[msgSender()] - _amount;
            
            require(token.transfer(msgSender(), _amount));

            emit LogWithdrawal(msgSender(), _amount);
            return true;

        }
     
function playNow(uint256 _value)
        public            
        returns (bool) 
        {
        
        require (_value != 0);
        require (_value > 0);
        
        // transfer play entry fee to the smart contract 
        //       
        require(token.balanceOf(msgSender()) > _value); 
        //token.approve(spender, _value);
        token.transferFrom(msgSender(), address(this), _value);   

        fundsByParticipants[msgSender()] = fundsByParticipants[msgSender()] + _value;

        //fundsByParticipantsByTeam[msgSender()][teamid] = _value ;

        // other data to be updated
        emit LogPlay(msgSender());
        return true;
    }

/*     
  
function changeTeam(uint _value)
        public
        onlyBeforeStart
        onlyNotCanceled
        returns (bool success)
        {
        
        emit ChangeTeamDone();
        return true;
    }
*/

/*
 function updateWinningData(address[] memory _winners, uint256[] memory _amount)
        public
        onlyOwner
        onlyAfterEnd
        onlyNotCanceled
        returns (bool success)
    {
        
        // update the winning address with
        // winning amount 
        // and playid 
        // since more than one play is possible from
        // the same address 
        
        
        for (uint i=0; i<_winners.length; i++) {
            address _winner = _winners[i];

            if(participantsList[_winner]) {
                // participantsList[_playerId].points =  _points[i]; 
                fundsByWinners[_winner] = 

            }
        }
      

        emit WinnersDataUpdated();
        return true;
    }
 */

 function updatePlayerPoints(uint[] memory _playerIds, uint[] memory _points)
        public
        onlyOwner
        onlyAfterEnd
        onlyNotCanceled
        returns (bool success)
    {
        //
        // update player points  
        // 
        
        for (uint i=0; i<_playerIds.length; i++) {
            uint _playerId = _playerIds[i];

            if(playersList[_playerId]) {
                playersData[_playerId].points =  _points[i];   
            }
        }
       
        emit PlayerDataUpdated();
        return true;
    }


    // function getContestants ()
    //     view
    //     public
    //     returns(memory address[])
    //     {
    //         return contestants;
    //     }
      
function cancelContest()
        public  
        onlyOwner        
        returns (bool success)
    {
        canceled = true;

        emit ContestCanceled();
        return true;
    }

    modifier onlyAfterStart()  {
        require (block.timestamp > startTime) ;
        _;
    }

    modifier onlyBeforeStart() {
        require (block.timestamp < startTime) ;
        _;
    }

    modifier onlyNotCanceled() {
        require (!canceled);
        _;
    }


    //     modifier onlyOwner() {
    //     require(_owner == _msgSender(), "Ownable: caller is not the owner");
    //     _;
    // }

    modifier onlyBeforeEnd()  {
        require (block.timestamp < endTime) ;
        _;
    }

    modifier onlyAfterEnd()  {
        require (block.timestamp > endTime) ;
        _;
    }

    modifier onlyAfterSettlement() {
        require (settled) ;
        _;
    }

    modifier onlyEndedOrCanceled()   {
        require (block.timestamp > endTime || canceled) ;
        _;
    }

    modifier onlyOwner() {
        assert (msgSender() == owner) ;
        _;
    }

}