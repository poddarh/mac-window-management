const render = ({ output }) => {
  if (typeof output === "undefined") return null;
  const status = output.status;
  if (status === "inactive") return <div>􀙈</div>;

  const ssid = output.ssid.replace(/\s/g, '\xA0');
  return <div> {ssid}</div>;
};

export default render;
