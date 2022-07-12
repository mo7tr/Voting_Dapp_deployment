// == Import npm
import { useState, useEffect } from "react";
import SimpleStorageContract from "./contracts/SimpleStorage.json";
import getWeb3 from "./getWeb3";

// == Import assets
import "./App.css";

// == Import Components
import Events from "./components/Events";
import Address from "./components/Address";

/*
  On a déploy un contrat SimpleStorage sur ganache.
  Ce contrat permet de set une valeur dans une variable d'état et de recup cette valeur.

  On va se créer un Front en React pour intéragir avec ce contrat. Pour ça on va utiliser la librairie web3js.
  L'initialisation et la configuration de web3 dans notre Front se fait depuis le fichier getWeb3.js.
  Il nous permet de recup les infos depuis Metamask.

  Au montage du composant on va utiliser le provider web3 (metamask) pour plusieurs chose:
  - Recup les comptes => dans le state
  - Recup le network sur lequel l'utilisateur est connecté et sur lequel le contrat a été déployé (ganache)
  - Pouvoir se faire une nouvelle instance de ce contrat => dans le state
  - Recup la valeur de la variable d'état pour l'afficher => dans le state

  Maintenant on va pouvoir intéragir avec ce contrat en executant ses fonctions
  - Recup la variable d'état
  - Ecrire dans cette variable d'état
  - Recup les events pour les afficher

  Il existe trois façon de recup les events d'un contrat :
  - Lorsqu'on déclenche une Tx, on peut recup l'instance de cette Tx et recup l'event qu'elle a émit.
      => Les console.log dans la fonction handleClick
  - Recup tous les events antérieurs.
      => Au moment du montage du composant dans le hook useEffect
  - Ecouter les events du contrat en direct. Dès qu'un account va déclencher l'event qu'on écoute, on va pouvoir le recup.
      => Au moment du montage du composant dans le hook useEffect

*/

// == Composant
function App() {
  const [value, setValue] = useState(""); // champ controlé
  const [storageValue, setStorageValue] = useState(null);
  const [web3, setWeb3] = useState(null);
  const [accounts, setAccounts] = useState(null);
  console.log("accounts =>", accounts);
  const [contract, setContract] = useState(null);
  const [addresses, setAdresses] = useState([]);
  console.log("addresses =>", addresses);

  console.log("# 0");

  // Rendu initial du composant
  useEffect(
    // On veut recup les infos du contrat déployé au moment du montage du composant
    // Pour ça on doit déclarer une fonction async dans le hook useEffect
    () => {
      console.log("# 1");
      async function setUpWeb3() {
        console.log("# 2");
        try {
          // On recup le provider Metamask installé sur le navigateur
          const web3Provider = await getWeb3();

          // On recup les comptes
          const accounts = await web3Provider.eth.getAccounts();

          // On recup l'id du network
          const networkId = await web3Provider.eth.net.getId();
          // On recup le network sur lequel on a deploy le contrat avec truffle migrate (on a l'info dans l'ABI du contrat ./contracts)
          const deployedNetwork = SimpleStorageContract.networks[networkId];
          // On crée une nouvelle instance du contrat via son ABI, le network et l'adresse sur laquel le contrat a été déployé
          const instance = new web3Provider.eth.Contract(
            SimpleStorageContract.abi,
            deployedNetwork && deployedNetwork.address
          );

          ///////////

          // let options = {
          //   fromBlock: 0,
          //   toBlock: "latest",
          // };

          // On recup tous les events passés du contrat
          // let listAddress = await instance.getPastEvents("SetValue", options);

          //////////

          let options1 = {
            fromBlock: 0,
          };

          let listAddress = [];

          // Ici on se met en écoute des émissions d'events. On rajoute chaque nouvel event dans le state
          // L'avantage ici c'est qu'on va pouvoir recup tous les nouveaux events, même ceux déclenchés par d'autres accounts
          instance.events
            .SetValue(options1)
            .on("data", (event) => listAddress.push(event));

          // On execute une fonction view
          const response = await instance.methods.get().call();

          // On mémorise dans le state les infos
          setStorageValue(response);
          setWeb3(web3Provider); // Ne set rien. Pas possible de mémoriser le web3 provider dans le state ?
          setAccounts(accounts);
          setContract(instance);
          setAdresses(listAddress);
        } catch (error) {
          alert(
            `Failed to load web3, accounts, or contract. Check console for details.`
          );
          console.error(error);
        }
      }

      // On doit executer la fonction async
      console.log("# 3");
      setUpWeb3();
      console.log("# 4");
    },
    []
  );

  const handleClick = async () => {
    // On ecrit sur la BC, donc await
    const receipt = await contract.methods
      .set(value)
      .send({ from: accounts[0] });
    // On recup la nouvelle valeur
    const newValue = await contract.methods.get().call();

    // On recup un event d'une transaction qu'on vient d'émettre !
    // Attention cependant : si on rajoute déjà les transactions dans le state depuis le useEffet,
    // le faire ici aussi fera doublon.
    // => Juste console.log() histoire de tester quand même
    console.log(
      "l'adresse est celle ci: " + receipt.events.SetValue.returnValues.addr
    );
    console.log(
      "la data est celle ci: " + receipt.events.SetValue.returnValues.newValue
    );
    console.log("receipt =>", receipt);

    // On la mémorise la nouvelle value dans le state
    setStorageValue(newValue);

    // UX: on vide le champ
    setValue("");
  };

  return (
    <div className="App">
      <h1>Good to Go!</h1>
      <p>Your Truffle Box is installed and ready.</p>

      <Address addr={accounts} />

      <h2>Smart Contract Example</h2>
      <div>The stored value is: {storageValue}</div>
      <input
        type="text"
        value={value}
        onChange={(evt) => {
          setValue(evt.currentTarget.value);
        }}
      />
      <button onClick={handleClick}>Set value</button>

      <Events addresses={addresses} />
    </div>
  );
}

// == Export
export default App;
