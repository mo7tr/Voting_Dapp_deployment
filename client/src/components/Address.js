// == Import
// import PropTypesLib from "prop-types";

// == Composant
function Address({ addr }) {
  return (
    <div>
      <p>Voici l'adresse que vous utilisez: {addr}</p>
    </div>
  );
}

// Vérification du type des props
// Address.propTypes = {
//   addr: PropTypesLib.string.isRequired,
// };

// == Export
export default Address;
