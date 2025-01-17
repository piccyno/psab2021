/*
This software is distributed under MIT/X11 license
Copyright (c) 2021 Fabrizio Chelo & Simone Picciau - University of Cagliari
Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:
The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./MuniCoin.sol";

contract Comune {

	/* STRUTTURE DATI */
	struct SoggettoAccreditato {
		uint256 idSoggettoAccreditato;  
		string nome;
		address indirizzo;
		uint256 balance;
	}

	struct Impegno {
		uint256 idImpegno;	// futura implementazione
		bytes32 nome;
		uint256 anno;
		uint256 balance;
	}

	struct GiustificativoCifrato {
	    uint8[] OTC;
	    uint8[] cipherText;
	    address indirizzo;
	    uint8 status;
	    uint256 idGiustificativo;
	}

	/* VARIABILI */
	string public name = "Comune";
	uint256 public idImpegno = 0; //contatore globale per gli impegni
	uint256 public idGiustificativo = 0; //contatore globale per i giustificativi

	uint256 public idSoggettoAccreditato = 0; //contatore globale per i soggetti accreditati

	MuniCoin public municoin;
	address owner;

	// indirizzo sogg. accreditato => SoggettoAccreditato
	mapping(address => SoggettoAccreditato) public soggettiAccreditati; // elenco dei soggetti accreditati

	// identificativo impegno => impegno
	mapping(uint256 => Impegno) public impegni; // elenco degli impegni di spesa

	// id giustificativo => testo json del giustificativo criptato
	// mapping(uint256 => string ) public giustificativi;
	GiustificativoCifrato[] valoriGiustificativi;
	uint256[] public idGiustificativi;

	//restituisce il saldo del contratto
	function getBalance() external view returns (uint256) {
		return address(this).balance;  //implementazione da rivedere
	}

	constructor(MuniCoin _municoin) public {
		municoin = _municoin;
		owner = msg.sender;
	}
	
	
    function checkSoggettoAccreditato(address indirizzo) public view returns(bool){
        if(bytes(SoggettoAccreditato[indirizzo]).length>0){
            return true;
        }
        else{
            return false;
        }
    }
	  

	modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
	
	modifier onlySAorOwner {
        require(msg.sender == owner || checkSoggettoAccreditato(msg.sender));
        _;
    }


	/**
	 * aggiunge un giustificativo
	 * @param:
	 * _OTC: One Time Code
	 * _cipherText: Giustificativo cifrato
	 */
	function addGiustificativo(uint8[] memory _OTC, uint8[] memory _cipherText) public onlySAorOwner {
	    GiustificativoCifrato memory giustificativo;
	    uint8[] memory OTC = new uint8[](_OTC.length);
	    uint8[] memory cipherText = new uint8[](_cipherText.length);
		
	    uint8 i;
	    for(i=0; i<_OTC.length; i++){
	        OTC[i] = _OTC[i];
	    }    
	    for(i=0; i<_cipherText.length; i++){
	        cipherText[i] = _cipherText[i];
	    }    
		
	    giustificativo = GiustificativoCifrato(OTC, cipherText, msg.sender, 0, idGiustificativo);
	    valoriGiustificativi.push(giustificativo);
	    idGiustificativo++;
	}


	/**
	 * restituisce il giustificativo dato il suo id
	 * @param:
	 * _idGiustificativo: id del giustificativo
	 */
	function getGiustificativo(uint256 _idGiustificativo) public view onlySAorOwner returns (GiustificativoCifrato memory){
	    return valoriGiustificativi[_idGiustificativo];
	}


	/**
	 * restituisce l'id dell'ultimo giustificativo inserito
	 */
	function getUltimoIdGiustificativo() public view returns (uint256){
	    return idGiustificativo -1;
	}


	/**
	 * restituisce il nome del contratto
	 */
	function getName() public view returns (string memory)
	{
	    return name;
	}


	/**
	 * imposta il nome del contratto
	 */
	function setName(string memory _nome) public   
	{
	    name = _nome;
	}


	/**
	 * !!! deprecated !!!
	 */
	function setNum(uint256 _num) public   
	{
	    idImpegno = _num;
	}


	/**
	 * !!! deprecated !!!
	 */
	function getNum() public view returns (uint256)
	{
	    return idImpegno;
	} 


	/**
	 * restituisce la lista dei giustificativi
	 */
	function getValoriGiustificativi() public view onlySAorOwner returns (GiustificativoCifrato[] memory)
	{
	    return valoriGiustificativi;
	} 


	/**
	 * !!! deprecated !!!
	 */
	function getSoggettoAccreditato(address account) public view returns (SoggettoAccreditato memory)
	{
		SoggettoAccreditato memory soggetto = soggettiAccreditati[account];   
	    return soggetto;
	} 


	/**
	 * !!! deprecated !!!
	 */
	function addSoggettoAccreditato(string memory nome, address indirizzo) public {
	    SoggettoAccreditato memory soggettoAccreditato;
	    soggettoAccreditato = SoggettoAccreditato(idSoggettoAccreditato, nome,indirizzo, 0);   
	    soggettiAccreditati[indirizzo] = soggettoAccreditato;
	    idSoggettoAccreditato++;
	}


	/**
	 * Pagamento
	 * @param:
	 * destinatario: destinatario della moneta
	 * importo: importo da destinare
	 */
	function pagaSoggettoMNC(address destinatario, uint importo) public onlyOwner payable {
		require(importo > 0, "L'importo è una cifra positiva");
		require(getBalance()-importo >= 0, "L'importo è coperto sal saldo");
		municoin.transfer(destinatario, importo);
	}


	/**
	 * Imposta il giustificativo come pagato
	 * @param:
	 * _idGiustificativo: giustificativo da impostare come pagato
	 */
	function setPagato(uint256 _idGiustificativo) public {
		valoriGiustificativi[_idGiustificativo].status = 1;
	}

}
