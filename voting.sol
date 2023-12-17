//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Voting {
    address public owner;
    constructor () {
        owner=msg.sender;
    }

    // Структура для представления кандидата
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    //Cтруктура для представления избирателя
    struct Voter {
        address voterAd;
        uint256 voteInd;
        uint256 sentAmount; // Размер средств, отправленных при голосовании
    }

    // Массив кандидатов
    Candidate[] public candidates;
    
    Voter[] public addressesWhoVoted;

    //отслеживание адресов, которые уже голосовали
    mapping(address => bool) public hasVoted;
    // Отслеживание кандидата, за которого голосовал каждый адрес
    mapping(address => uint256) public votes;
    // Массив для хранения сумм, отправленных каждым пользователем
    mapping(address => uint256) public userBalances;

    // Функция добавления кандидата
    function addCandidate(string memory name) public {
        // Проверяем, что имя кандидата не является пустым
        require(bytes(name).length > 0, "Candidate name cannot be empty");
        candidates.push(Candidate(name, 0));
    }

    // Функция голосования за кандидата
    function vote(uint256 candidateIndex) public payable {
        // Проверяем, что адрес еще не голосовал
        require(!hasVoted[msg.sender],"you have already voted!");
        // Проверяем, что индекс кандидата действителен
        require(candidateIndex < candidates.length, "invalid candidate index");
        // Проверяем, что отправленное количество эфира больше 0
        require(msg.value > 0, "sent amount must be greater than 0");
        //увеличиваем счетчик голосов для выбранного кандидата
        candidates[candidateIndex].voteCount++;

        addressesWhoVoted.push(Voter(msg.sender,candidateIndex,msg.value));

        // Отмечаем, что адрес проголосовал
        hasVoted[msg.sender] = true;
         
    }


    // Функция получения общего количества голосов для конкретного кандидата
    function getVotesCount(uint256 candidateIndex) public view returns (uint256) {
        // Проверяем, что индекс кандидата действителен
        require(candidateIndex < candidates.length, "invalid candidate index");

        // Возвращаем количество голосов для выбранного кандидата
        return candidates[candidateIndex].voteCount;
    }
     // Функция определения победителя
    function getWinner() public view returns (uint256, string memory, uint256) {
    require(candidates.length > 0, "No candidates available");

    uint256 maxVotes = 0;
    string memory winnerName;
    uint256 winnerId;

    for (uint256 i = 0; i < candidates.length; i++) {
        if (candidates[i].voteCount > maxVotes) {
            maxVotes = candidates[i].voteCount;
            winnerId = i;
            winnerName = candidates[i].name;
        }
    }

    return (winnerId, winnerName, maxVotes);
}

    function getVotersForWinner() public view returns (address[] memory) {
    require(candidates.length > 0, "No candidates available");

    // Получаем информацию о победителе
    (uint256 winnerId, , ) = getWinner();

    // Создаем временный массив для хранения адресов голосующих за победителя
    address[] memory votersForWinner = new address[](candidates[winnerId].voteCount);

    // Счетчик для отслеживания текущего индекса в массиве votersForWinner
    uint256 currentIndex = 0;

    // Проходимся по массиву addressesWhoVoted и добавляем адреса голосующих за победителя
    for (uint256 i = 0; i < addressesWhoVoted.length; i++) {
        if (addressesWhoVoted[i].voteInd == winnerId) {
            votersForWinner[currentIndex] = addressesWhoVoted[i].voterAd;
            currentIndex++;
        }
    }

    return votersForWinner;
}

   function sendEthToWinners() public payable {

    ///Проверяем, что вызывающий функцию — владелец контракта
    require(msg.sender == owner, "Only the contract owner can execute this function");
    // Получаем информацию о победителе
    (uint256 winnerId, , ) = getWinner();

    // Создаем временный массив для хранения адресов и сумм голосующих за победителя
    address[] memory votersForWinner = new address[](candidates[winnerId].voteCount);
    uint256[] memory amountsForWinner = new uint256[](candidates[winnerId].voteCount);

    // Счетчик для отслеживания текущего индекса в массивах votersForWinner и amountsForWinner
    uint256 currentIndex = 0;

    // Проходимся по массиву addressesWhoVoted и добавляем адреса и суммы голосующих за победителя
    for (uint256 i = 0; i < addressesWhoVoted.length; i++) {
        if (addressesWhoVoted[i].voteInd == winnerId) {
            votersForWinner[currentIndex] = addressesWhoVoted[i].voterAd;
            amountsForWinner[currentIndex] = addressesWhoVoted[i].sentAmount;
            currentIndex++;
        }
    }

    // Проверяем, что есть достаточно эфира для отправки
    require(address(this).balance >= getTotalAmount(amountsForWinner), "ERROR");

    // Отправляем сумму ETH каждому адресу из массива
    for (uint256 i = 0; i < votersForWinner.length; i++) {
        payable(votersForWinner[i]).transfer(amountsForWinner[i]);
    }

    // Получаем текущий баланс контракта
    uint256 contractBalance = address(this).balance;
    // Проверяем, что есть остаток для отправки
    require(contractBalance > 0, "No remaining balance to withdraw");
    // Отправляем остаток баланса владельцу контракта
    payable(owner).transfer(contractBalance);
}

// Вспомогательная функция для подсчета общей суммы в массиве
function getTotalAmount(uint256[] memory amounts) internal pure returns (uint256) {
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < amounts.length; i++) {
        totalAmount += amounts[i];
    }
    return totalAmount;
}

}
