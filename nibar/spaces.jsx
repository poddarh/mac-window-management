import Desktop from "./lib/Desktop.jsx";
import Error from "./lib/Error.jsx";
import parse from "./lib/parse.jsx";
import styles, { typographyStyle } from "./lib/styles.jsx";

const style = {
  padding: "0 8px",
  display: "grid",
  gridAutoFlow: "column",
  gridGap: "20px",
  position: "fixed",
  overflow: "hidden",
  left: "0px",
  bottom: "0px",
  color: styles.colors.dim,
  ...typographyStyle
};

export const refreshFrequency = false;
export const command = "./nibar/scripts/spaces.sh";

export const render = ({ output }) => {
  const data = parse(output);
  if (typeof data === "undefined") {
    return (
      <div style={style}>
        <Error msg="Error: unknown script output" side="left" />
      </div>
    );
  }
  if (typeof data.error !== "undefined") {
    return (
      <div style={style}>
        <Error msg={`Error: ${data.error}`} side="left" />
      </div>
    );
  }
  return (
    <div style={style}>
      <Desktop
        output={data.spaces}
        displays={data.displays}
      />
    </div>
  );
};

export default null;
