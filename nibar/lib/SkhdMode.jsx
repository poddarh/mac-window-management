import styles from "./styles.jsx";

const render = ({ output }) => {
  if (output === "default") return null;
  return (
    <div style={{backgroundColor: "red", paddingRight: 20, paddingLeft: 20, fontWeight: "bold"}}>
      <span>{output.toUpperCase()}</span>
    </div>
  );
};

export default render;
