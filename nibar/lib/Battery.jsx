import styles from "./styles.jsx";

const render = ({ output }) => {
  const { charging, percentage } = output;
  return (
    <div>
      <div
        style={
          percentage < 10 && charging === false
            ? { color: styles.colors.red }
            : null
        }
      >
        <span>{charging ? "⚡" : null} {percentage}%</span>
      </div>
    </div>
  );
};

export default render;
