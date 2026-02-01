import styles from "./styles.jsx";

const render = ({ output }) => {
  if (output === null || output["has-fullscreen-zoom"] === false) { return null; }
  return (
    <div style={{ backgroundColor: "lightblue", color: "black", paddingRight: 20, paddingLeft: 20, fontWeight: "bold" }}>
      <span>FULLSCREEN</span>
    </div>
  );
};

export default render;
