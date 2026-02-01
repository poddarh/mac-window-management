import styles from "./styles.jsx";

const style = {
  color: styles.colors.red
}

const render = ({ output }) => {
  if (output === 0)
  	return <div style={style}></div>;
  return null;
};

export default render;
